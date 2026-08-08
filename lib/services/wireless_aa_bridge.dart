import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/projection_state.dart';
import 'aa_usb_aoap_service.dart';
import 'android_auto_engine.dart';

/// Event emitted by WirelessAABridge as the connection lifecycle progresses.
class AAConnectionEvent {
  final AAConnectionStep step;
  final String message;
  final Map<String, dynamic>? data;

  const AAConnectionEvent({
    required this.step,
    required this.message,
    this.data,
  });
}

/// WirelessAABridge orchestrates the full Wireless Android Auto connection:
///
/// On Linux/RPi:
///   1. Creates a Wi-Fi hotspot via nmcli (HeadUnit-OS SSID)
///   2. Makes the device Bluetooth-discoverable as "HeadUnit-OS" via bluetoothctl
///   3. Runs the Native Android Auto Protocol Engine (AOA 2.0 + TCP Demuxer)
///   4. Emits AAConnectionEvent stream for the Flutter UI
///
/// On Windows (development simulation):
///   - Replays the same lifecycle events with artificial delays so the
///     connection wizard UI can be developed and tested without Linux hardware.
class WirelessAABridge {
  static final WirelessAABridge _instance = WirelessAABridge._internal();
  factory WirelessAABridge() => _instance;
  WirelessAABridge._internal();

  Process? _openAutoProcess;
  bool _isRunning = false;

  final StreamController<AAConnectionEvent> _eventController =
      StreamController<AAConnectionEvent>.broadcast();

  Stream<AAConnectionEvent> get events => _eventController.stream;
  bool get isRunning => _isRunning;

  // ── Configuration constants ──────────────────────────────────────────────
  static const String _hotspotConnectionName = 'HeadUnit-OS';
  static const String _hotspotSsid = 'HeadUnit-OS';
  static const String _hotspotPassword = 'headunit2024';
  static const String _bluetoothAlias = 'HeadUnit-OS';

  // ── Public API ───────────────────────────────────────────────────────────

  /// Start the wireless Android Auto session.
  Future<void> startWirelessAndroidAuto() async {
    if (_isRunning) return;
    _isRunning = true;

    if (Platform.isWindows) {
      await _runWindowsSimulation();
    } else {
      await _runLinuxNative();
    }
  }

  /// Stop the session and clean up hotspot + BT discoverability.
  Future<void> stopWirelessAndroidAuto() async {
    _isRunning = false;

    _openAutoProcess?.kill(ProcessSignal.sigterm);
    _openAutoProcess = null;

    if (!Platform.isWindows) {
      try {
        await Process.run('nmcli', ['connection', 'down', _hotspotConnectionName]);
        await Process.run('bluetoothctl', ['discoverable', 'off']);
        await Process.run('bluetoothctl', ['pairable', 'off']);
      } catch (e) {
        if (kDebugMode) print('[WirelessAABridge] Cleanup error: $e');
      }
    }

    _emit(AAConnectionStep.idle, 'Disconnected');
  }

  /// Forward a touch input event to the OpenAuto process via stdin protocol.
  void sendTouchEvent(double normalizedX, double normalizedY, int action) {
    // action: 0=DOWN, 1=MOVE, 2=UP
    if (_openAutoProcess != null) {
      // OpenAuto reads touch events from stdin as: ACTION,X,Y\n
      _openAutoProcess!.stdin.writeln('$action,${(normalizedX * 10000).toInt()},${(normalizedY * 10000).toInt()}');
    }
    if (kDebugMode) {
      print('[WirelessAABridge] Touch → (${(normalizedX * 100).toStringAsFixed(1)}%, ${(normalizedY * 100).toStringAsFixed(1)}%) action=$action');
    }
  }

  // ── Linux native flow ────────────────────────────────────────────────────

  Future<void> _runLinuxNative() async {
    try {
      // Step 1: Wi-Fi hotspot
      _emit(AAConnectionStep.hotspotCreating, 'Creating Wi-Fi hotspot…');
      await _createHotspot();

      // Step 2: Bluetooth discoverable
      _emit(AAConnectionStep.bluetoothDiscoverable,
          'Waiting for Bluetooth pairing…',
          data: {'btName': _bluetoothAlias});
      await _makeBluetoothDiscoverable();

      // Step 3: Check USB AOA Mode or start Native Wi-Fi Socket Engine
      _emit(AAConnectionStep.waitingForPhone,
          'Open Android Auto on your phone');
      await _launchNativeAaEngine();

    } catch (e) {
      _emit(AAConnectionStep.error, 'Connection failed: $e');
      _isRunning = false;
      if (kDebugMode) print('[WirelessAABridge] Fatal error: $e');
    }
  }

  Future<void> _createHotspot() async {
    // Check if the profile already exists; create it if not.
    final check = await Process.run('nmcli', ['connection', 'show', _hotspotConnectionName]);
    if (check.exitCode != 0) {
      final result = await Process.run('nmcli', [
        'connection', 'add',
        'type', 'wifi',
        'con-name', _hotspotConnectionName,
        'ssid', _hotspotSsid,
        'mode', 'ap',
        'ipv4.method', 'shared',
        'wifi-sec.key-mgmt', 'wpa-psk',
        'wifi-sec.psk', _hotspotPassword,
        'autoconnect', 'no',
      ]);
      if (result.exitCode != 0) {
        throw Exception('nmcli create failed: ${result.stderr}');
      }
    }

    final up = await Process.run('nmcli', ['connection', 'up', _hotspotConnectionName]);
    if (up.exitCode != 0) {
      throw Exception('nmcli up failed: ${up.stderr}');
    }

    if (kDebugMode) {
      print('[WirelessAABridge] Hotspot active: SSID=$_hotspotSsid pass=$_hotspotPassword');
    }
  }

  Future<void> _makeBluetoothDiscoverable() async {
    // Rename device, enable discoverable and pairable modes.
    await Process.run('bluetoothctl', ['system-alias', _bluetoothAlias]);
    await Process.run('bluetoothctl', ['discoverable', 'on']);
    await Process.run('bluetoothctl', ['pairable', 'on']);
    if (kDebugMode) {
      print('[WirelessAABridge] Bluetooth discoverable as: $_bluetoothAlias');
    }
  }

  Future<void> _launchNativeAaEngine() async {
    _emit(AAConnectionStep.tlsHandshake, 'Securing connection via Native AA Engine…');
    
    // Check USB AOA Mode
    await AaUsbAoapService().checkForAndroidDeviceAndInitiateAoap();

    // Connect Native Protocol Socket
    _emit(AAConnectionStep.channelDiscovery, 'Negotiating video & audio channels…');
    final connected = await AndroidAutoEngine().connectNativeSocket(port: 50001);

    if (connected) {
      _emit(AAConnectionStep.streaming, 'Android Auto streaming',
          data: {'deviceName': 'Android Phone', 'phoneBattery': 85});
    } else {
      _emit(AAConnectionStep.error, 'Could not connect to Android Auto stream');
      _isRunning = false;
    }
  }

  // ── Windows simulation flow ──────────────────────────────────────────────

  Future<void> _runWindowsSimulation() async {
    const delays = [
      (800, AAConnectionStep.hotspotCreating, 'Creating Wi-Fi hotspot…', null),
      (2200, AAConnectionStep.bluetoothDiscoverable, 'Select "HeadUnit-OS" on your phone\'s Bluetooth menu', {'btName': _bluetoothAlias}),
      (3500, AAConnectionStep.waitingForPhone, 'Open Android Auto on your phone…', null),
      (2000, AAConnectionStep.tlsHandshake, 'Securing TLS connection…', null),
      (1200, AAConnectionStep.channelDiscovery, 'Negotiating video & audio channels…', null),
      (1000, AAConnectionStep.streaming, 'Android Auto streaming', {'deviceName': 'Pixel 9 Pro', 'phoneBattery': 78}),
    ];

    for (final (delayMs, step, msg, data) in delays) {
      if (!_isRunning) return;
      await Future.delayed(Duration(milliseconds: delayMs));
      if (!_isRunning) return;
      _emit(step, msg, data: data);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _emit(AAConnectionStep step, String message, {Map<String, dynamic>? data}) {
    if (!_eventController.isClosed) {
      _eventController.add(AAConnectionEvent(step: step, message: message, data: data));
    }
    if (kDebugMode) {
      print('[WirelessAABridge] [$step] $message');
    }
  }

  void dispose() {
    _eventController.close();
  }
}
