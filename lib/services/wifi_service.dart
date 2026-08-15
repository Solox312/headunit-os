import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/wifi_network.dart';

class WifiConnectResult {
  final bool success;
  final String? errorMessage;
  final bool isPermissionDenied;

  const WifiConnectResult({
    required this.success,
    this.errorMessage,
    this.isPermissionDenied = false,
  });
}

/// System service for scanning, connecting, and managing Wi-Fi networks on Linux / Raspberry Pi via `nmcli`.
class WifiService {
  static final WifiService _instance = WifiService._internal();
  factory WifiService() => _instance;
  
  WifiService._internal() {
    _disableApAutoconnect();
  }

  bool? _isNmcliAvailableCache;

  /// Private helper to run nmcli commands with automatic fallback to sudo if Polkit denies authorization.
  Future<ProcessResult> _runNmcli(List<String> args) async {
    ProcessResult result = await Process.run('nmcli', args);
    if (result.exitCode != 0 && result.stderr.toString().contains('Not authorized to control networking')) {
      if (kDebugMode) {
        print('[WifiService] nmcli ${args.join(' ')} unauthorized by Polkit. Retrying via sudo...');
      }
      result = await Process.run('sudo', ['nmcli', ...args]);
    }
    return result;
  }

  /// Proactively disables autoconnect and deletes any client profile for the local AP.
  void _disableApAutoconnect() async {
    if (await isNmcliAvailable()) {
      try {
        // Delete the connection profile to make sure NetworkManager never tries to connect
        await _runNmcli(['connection', 'delete', 'RPi_HeadUnit_5G']);
        
        // If the interface is currently connected to the local AP, force disconnect
        final statusResult = await _runNmcli(['-t', '-f', 'ACTIVE,SSID,DEVICE', 'dev', 'wifi']);
        if (statusResult.exitCode == 0) {
          for (var line in statusResult.stdout.toString().split('\n')) {
            final parts = line.split(':');
            if (parts.length >= 3 && parts[1].trim() == 'RPi_HeadUnit_5G' && (parts[0].trim() == 'yes' || parts[0].trim() == '*')) {
              final dev = parts[2].trim();
              await _runNmcli(['device', 'disconnect', dev]);
            }
          }
        }
      } catch (_) {}
    }
  }

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
      final result = await _runNmcli(['radio', 'wifi']);
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
      final result = await _runNmcli(['radio', 'wifi', enabled ? 'on' : 'off']);
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
      ProcessResult result = await _runNmcli([
        '-t',
        '-f',
        'SSID,SIGNAL,SECURITY,IN-USE,BSSID',
        'dev',
        'wifi',
        'list',
        '--rescan',
        'yes'
      ]);

      // If rescan fails (common on some platforms when AP mode is active or interface is busy),
      // fallback to reading the cached Wi-Fi list without forcing a rescan.
      if (result.exitCode != 0) {
        if (kDebugMode) {
          print('[WifiService] nmcli list --rescan yes failed: ${result.stderr}. Falling back to cached list...');
        }
        result = await _runNmcli([
          '-t',
          '-f',
          'SSID,SIGNAL,SECURITY,IN-USE,BSSID',
          'dev',
          'wifi',
          'list',
          '--rescan',
          'no'
        ]);
      }

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
  Future<WifiConnectResult> connectToNetwork(String ssid, String password) async {
    if (!await isNmcliAvailable()) {
      if (kDebugMode) print('[WifiService] Simulator mode: Mocking connection to "$ssid"');
      await Future.delayed(const Duration(seconds: 1));
      return const WifiConnectResult(success: true);
    }

    try {
      List<String> args = ['dev', 'wifi', 'connect', ssid];
      if (password.isNotEmpty) {
        args.addAll(['password', password]);
      }

      ProcessResult result = await _runNmcli(args);

      if (result.exitCode == 0) {
        if (kDebugMode) print('[WifiService] Successfully connected to $ssid');
        return const WifiConnectResult(success: true);
      } else {
        final stderr = result.stderr.toString();
        if (kDebugMode) print('[WifiService] Failed to connect to $ssid: $stderr');

        if (stderr.contains('Not authorized to control networking')) {
          return const WifiConnectResult(
            success: false,
            errorMessage: 'NetworkManager Permission Error: Create /etc/polkit-1/rules.d/10-networkmanager.rules or configure passwordless sudo for nmcli.',
            isPermissionDenied: true,
          );
        }

        return WifiConnectResult(
          success: false,
          errorMessage: 'Failed to connect to "$ssid": ${stderr.trim()}',
        );
      }
    } catch (e) {
      if (kDebugMode) print('[WifiService] Connect exception: $e');
      return WifiConnectResult(
        success: false,
        errorMessage: 'Connect exception: $e',
      );
    }
  }

  /// Disconnect current active Wi-Fi connection on interface wlan0 (or primary wifi dev).
  Future<bool> disconnectNetwork() async {
    if (!await isNmcliAvailable()) return true;

    try {
      final devResult = await _runNmcli(['-t', '-f', 'DEVICE,TYPE', 'dev']);
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

      final result = await _runNmcli(['dev', 'disconnect', wifiDev]);
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
      final result = await _runNmcli(['-t', '-f', 'ACTIVE,SSID,DEVICE', 'dev', 'wifi']);
      if (result.exitCode == 0) {
        for (var line in result.stdout.toString().split('\n')) {
          final parts = line.split(':');
          if (parts.length >= 3 && (parts[0].trim() == 'yes' || parts[0].trim() == '*')) {
            final ssid = parts[1].trim();
            if (ssid == 'RPi_HeadUnit_5G') continue; // Ignore local AP interface
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
      final result = await _runNmcli(['-t', '-f', 'IP4.ADDRESS', 'dev', 'show', device]);
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
    if (ssid.isEmpty || ssid == 'RPi_HeadUnit_5G') return null;

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
