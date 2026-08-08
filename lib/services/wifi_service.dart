import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/wifi_network.dart';

/// System service for scanning, connecting, and managing Wi-Fi networks on Linux / Raspberry Pi via `nmcli`.
class WifiService {
  static final WifiService _instance = WifiService._internal();
  factory WifiService() => _instance;
  WifiService._internal();

  bool? _isNmcliAvailableCache;

  /// Check if NetworkManager (`nmcli`) CLI tool is available on this system.
  Future<bool> isNmcliAvailable() async {
    if (_isNmcliAvailableCache != null) return _isNmcliAvailableCache!;
    if (!Platform.isLinux) {
      _isNmcliAvailableCache = false;
      return false;
    }
    try {
      final result = await Process.run('which', ['nmcli']);
      _isNmcliAvailableCache = result.exitCode == 0;
      return _isNmcliAvailableCache!;
    } catch (e) {
      _isNmcliAvailableCache = false;
      return false;
    }
  }

  /// Check if Wi-Fi radio is currently powered on.
  Future<bool> isWifiRadioOn() async {
    if (!await isNmcliAvailable()) return true; // Mock default
    try {
      final result = await Process.run('nmcli', ['radio', 'wifi']);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim().toLowerCase() == 'enabled';
      }
    } catch (e) {
      if (kDebugMode) print('[WifiService] Error checking radio state: $e');
    }
    return true;
  }

  /// Turn Wi-Fi radio on or off.
  Future<bool> setWifiRadio(bool enabled) async {
    if (!await isNmcliAvailable()) return true;
    try {
      final result = await Process.run('nmcli', ['radio', 'wifi', enabled ? 'on' : 'off']);
      return result.exitCode == 0;
    } catch (e) {
      if (kDebugMode) print('[WifiService] Error setting radio state: $e');
      return false;
    }
  }

  /// Scan for available Wi-Fi access points.
  Future<List<WifiNetwork>> scanNetworks() async {
    if (!await isNmcliAvailable()) {
      return _getMockNetworks();
    }

    try {
      // Run nmcli scan with rescan
      final result = await Process.run('nmcli', [
        '-t',
        '-f',
        'SSID,SIGNAL,SECURITY,IN-USE,BSSID',
        'dev',
        'wifi',
        'list',
        '--rescan',
        'yes'
      ]);

      if (result.exitCode != 0) {
        if (kDebugMode) print('[WifiService] nmcli list failed: ${result.stderr}');
        return _getMockNetworks();
      }

      final lines = result.stdout.toString().split('\n');
      final Map<String, WifiNetwork> networks = {};

      for (var line in lines) {
        if (line.trim().isEmpty) continue;
        final net = _parseNmcliLine(line);
        if (net != null && net.ssid.isNotEmpty) {
          // Keep network with highest signal if duplicates found
          if (!networks.containsKey(net.ssid) || (networks[net.ssid]!.signalStrength < net.signalStrength)) {
            networks[net.ssid] = net;
          }
        }
      }

      final list = networks.values.toList();
      list.sort((a, b) {
        if (a.isConnected) return -1;
        if (b.isConnected) return 1;
        return b.signalStrength.compareTo(a.signalStrength);
      });

      return list;
    } catch (e) {
      if (kDebugMode) print('[WifiService] Scan exception: $e');
      return _getMockNetworks();
    }
  }

  /// Connect to a specific Wi-Fi network using SSID and optional password.
  Future<bool> connectToNetwork(String ssid, String password) async {
    if (!await isNmcliAvailable()) {
      if (kDebugMode) print('[WifiService] Simulator mode: Mocking connection to "$ssid"');
      await Future.delayed(const Duration(seconds: 2));
      return true;
    }

    try {
      List<String> args = ['dev', 'wifi', 'connect', ssid];
      if (password.isNotEmpty) {
        args.addAll(['password', password]);
      }

      final result = await Process.run('nmcli', args);
      if (result.exitCode == 0) {
        if (kDebugMode) print('[WifiService] Successfully connected to $ssid');
        return true;
      } else {
        if (kDebugMode) print('[WifiService] Failed to connect to $ssid: ${result.stderr}');
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('[WifiService] Connect exception: $e');
      return false;
    }
  }

  /// Disconnect current active Wi-Fi connection on interface wlan0 (or primary wifi dev).
  Future<bool> disconnectNetwork() async {
    if (!await isNmcliAvailable()) return true;

    try {
      final devResult = await Process.run('nmcli', ['-t', '-f', 'DEVICE,TYPE', 'dev']);
      String wifiDev = 'wlan0';
      if (devResult.exitCode == 0) {
        for (var line in devResult.stdout.toString().split('\n')) {
          final parts = line.split(':');
          if (parts.length >= 2 && parts[1].trim() == 'wifi') {
            wifiDev = parts[0].trim();
            break;
          }
        }
      }

      final result = await Process.run('nmcli', ['dev', 'disconnect', wifiDev]);
      return result.exitCode == 0;
    } catch (e) {
      if (kDebugMode) print('[WifiService] Disconnect exception: $e');
      return false;
    }
  }

  /// Fetch active connection info (SSID, IP Address, Device).
  Future<Map<String, String>> getCurrentStatus() async {
    if (!await isNmcliAvailable()) {
      return {
        'ssid': '',
        'ip': '',
        'device': '',
        'connected': 'false',
      };
    }

    try {
      final result = await Process.run('nmcli', ['-t', '-f', 'ACTIVE,SSID,DEVICE', 'dev', 'wifi']);
      if (result.exitCode == 0) {
        for (var line in result.stdout.toString().split('\n')) {
          final parts = line.split(':');
          if (parts.length >= 3 && (parts[0].trim() == 'yes' || parts[0].trim() == '*')) {
            final ssid = parts[1].trim();
            final dev = parts[2].trim();
            final ip = await _getDeviceIp(dev);
            return {
              'ssid': ssid,
              'ip': ip,
              'device': dev,
              'connected': 'true',
            };
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('[WifiService] Get status exception: $e');
    }

    return {
      'ssid': '',
      'ip': '',
      'device': '',
      'connected': 'false',
    };
  }

  Future<String> _getDeviceIp(String device) async {
    try {
      final result = await Process.run('nmcli', ['-t', '-f', 'IP4.ADDRESS', 'dev', 'show', device]);
      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        final line = result.stdout.toString().split('\n').first;
        final ipWithCidr = line.split(':').last.trim();
        return ipWithCidr.split('/').first; // Strips /24
      }
    } catch (_) {}
    return '';
  }

  WifiNetwork? _parseNmcliLine(String line) {
    // Escaped colons in SSID handling
    final regex = RegExp(r'(?<!\\):');
    final parts = line.split(regex).map((s) => s.replaceAll(r'\:', ':')).toList();
    if (parts.length < 4) return null;

    final ssid = parts[0].trim();
    if (ssid.isEmpty) return null;

    final signal = int.tryParse(parts[1].trim()) ?? 50;
    final security = parts[2].trim().isEmpty ? 'Open' : parts[2].trim();
    final inUse = parts[3].trim() == '*' || parts[3].trim().toLowerCase() == 'yes';
    final bssid = parts.length > 4 ? parts[4].trim() : null;

    return WifiNetwork(
      ssid: ssid,
      signalStrength: signal,
      security: security,
      isConnected: inUse,
      bssid: bssid,
    );
  }

  List<WifiNetwork> _getMockNetworks() {
    return const [];
  }
}
