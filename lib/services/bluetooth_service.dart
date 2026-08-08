import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/bluetooth_device.dart';

/// System service for scanning, pairing, connecting, and managing Bluetooth devices on Linux / Raspberry Pi via `bluetoothctl`.
class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  bool? _isBluetoothctlAvailableCache;

  Future<bool> isBluetoothctlAvailable() async {
    if (_isBluetoothctlAvailableCache != null) return _isBluetoothctlAvailableCache!;
    if (!Platform.isLinux) {
      _isBluetoothctlAvailableCache = false;
      return false;
    }
    try {
      final result = await Process.run('which', ['bluetoothctl']);
      _isBluetoothctlAvailableCache = result.exitCode == 0;
      return _isBluetoothctlAvailableCache!;
    } catch (e) {
      _isBluetoothctlAvailableCache = false;
      return false;
    }
  }

  /// Check if Bluetooth adapter power is turned on.
  Future<bool> isPowerOn() async {
    if (!await isBluetoothctlAvailable()) return true;
    try {
      final result = await Process.run('bluetoothctl', ['show']);
      if (result.exitCode == 0) {
        return result.stdout.toString().contains('Powered: yes');
      }
    } catch (e) {
      if (kDebugMode) print('[BluetoothService] Error checking power state: $e');
    }
    return true;
  }

  /// Turn Bluetooth adapter power on or off.
  Future<bool> setPower(bool enabled) async {
    if (!await isBluetoothctlAvailable()) return true;
    try {
      final result = await Process.run('bluetoothctl', ['power', enabled ? 'on' : 'off']);
      return result.exitCode == 0;
    } catch (e) {
      if (kDebugMode) print('[BluetoothService] Error setting power: $e');
      return false;
    }
  }

  /// Set HeadUnit OS discoverable & pairable status.
  Future<bool> setDiscoverable(bool discoverable) async {
    if (!await isBluetoothctlAvailable()) return true;
    try {
      final dResult = await Process.run('bluetoothctl', ['discoverable', discoverable ? 'on' : 'off']);
      final pResult = await Process.run('bluetoothctl', ['pairable', 'on']);
      return dResult.exitCode == 0 && pResult.exitCode == 0;
    } catch (e) {
      if (kDebugMode) print('[BluetoothService] Error setting discoverable: $e');
      return false;
    }
  }

  /// Get list of paired Bluetooth devices.
  Future<List<BluetoothDevice>> getPairedDevices() async {
    if (!await isBluetoothctlAvailable()) {
      return _getMockPairedDevices();
    }

    try {
      final result = await Process.run('bluetoothctl', ['paired-devices']);
      if (result.exitCode != 0) return _getMockPairedDevices();

      final List<BluetoothDevice> paired = [];
      final lines = result.stdout.toString().split('\n');

      for (var line in lines) {
        if (line.trim().startsWith('Device')) {
          final dev = BluetoothDevice.fromBluetoothctlLine(line, isPaired: true);
          final connected = await _isDeviceConnected(dev.macAddress);
          paired.add(dev.copyWith(isConnected: connected));
        }
      }

      return paired;
    } catch (e) {
      if (kDebugMode) print('[BluetoothService] getPairedDevices exception: $e');
      return _getMockPairedDevices();
    }
  }

  /// Scan for nearby Bluetooth devices.
  Future<List<BluetoothDevice>> scanDevices() async {
    if (!await isBluetoothctlAvailable()) {
      return _getMockDiscoveredDevices();
    }

    try {
      // Start background scan for 4 seconds
      final process = await Process.start('bluetoothctl', ['scan', 'on']);
      await Future.delayed(const Duration(seconds: 4));
      process.kill();

      final result = await Process.run('bluetoothctl', ['devices']);
      if (result.exitCode != 0) return _getMockDiscoveredDevices();

      final List<BluetoothDevice> discovered = [];
      final lines = result.stdout.toString().split('\n');

      for (var line in lines) {
        if (line.trim().startsWith('Device')) {
          final dev = BluetoothDevice.fromBluetoothctlLine(line);
          discovered.add(dev);
        }
      }

      return discovered;
    } catch (e) {
      if (kDebugMode) print('[BluetoothService] scanDevices exception: $e');
      return _getMockDiscoveredDevices();
    }
  }

  /// Pair and connect to a Bluetooth device by MAC address.
  Future<bool> pairAndConnect(String macAddress) async {
    if (!await isBluetoothctlAvailable()) {
      if (kDebugMode) print('[BluetoothService] Simulator: Mocking pair & connect to $macAddress');
      await Future.delayed(const Duration(seconds: 2));
      return true;
    }

    try {
      await Process.run('bluetoothctl', ['pair', macAddress]);
      await Process.run('bluetoothctl', ['trust', macAddress]);
      final connResult = await Process.run('bluetoothctl', ['connect', macAddress]);
      return connResult.exitCode == 0;
    } catch (e) {
      if (kDebugMode) print('[BluetoothService] pairAndConnect exception: $e');
      return false;
    }
  }

  /// Disconnect an active Bluetooth device.
  Future<bool> disconnect(String macAddress) async {
    if (!await isBluetoothctlAvailable()) return true;

    try {
      final result = await Process.run('bluetoothctl', ['disconnect', macAddress]);
      return result.exitCode == 0;
    } catch (e) {
      if (kDebugMode) print('[BluetoothService] disconnect exception: $e');
      return false;
    }
  }

  /// Unpair / Forget a Bluetooth device.
  Future<bool> removeDevice(String macAddress) async {
    if (!await isBluetoothctlAvailable()) return true;

    try {
      final result = await Process.run('bluetoothctl', ['remove', macAddress]);
      return result.exitCode == 0;
    } catch (e) {
      if (kDebugMode) print('[BluetoothService] removeDevice exception: $e');
      return false;
    }
  }

  Future<bool> _isDeviceConnected(String macAddress) async {
    try {
      final result = await Process.run('bluetoothctl', ['info', macAddress]);
      return result.stdout.toString().contains('Connected: yes');
    } catch (_) {
      return false;
    }
  }

  List<BluetoothDevice> _getMockPairedDevices() {
    return const [];
  }

  List<BluetoothDevice> _getMockDiscoveredDevices() {
    return const [];
  }
}
