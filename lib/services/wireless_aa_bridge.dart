import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/aa_protocol_types.dart';
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
///   2. Binds the native AA protocol socket (port 50001) so it's listening
///      before the phone is told where to dial in
///   3. Makes the device Bluetooth-discoverable as "HeadUnit-OS"
///   4. Spawns scripts/aa_wireless_handoff.py, which registers the Android
///      Auto Wireless RFCOMM profile with BlueZ and performs the Wi-Fi
///      credential handshake when the phone connects — without that SDP
///      record the phone treats us as plain headphones and never initiates
///      projection
///   5. Emits AAConnectionEvent stream for the Flutter UI, driven by the
///      handoff daemon's stdout events and the engine's socket state
///
/// On Windows (development simulation):
///   - Replays the same lifecycle events with artificial delays so the
///     connection wizard UI can be developed and tested without Linux hardware.
class WirelessAABridge {
  static final WirelessAABridge _instance = WirelessAABridge._internal();
  factory WirelessAABridge() => _instance;
  WirelessAABridge._internal();

  Process? _handoffProcess;
  StreamSubscription<AAEngineState>? _engineStateSub;
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

  /// Head unit's own IP on the hotspot subnet — nmcli ipv4.method=shared
  /// always assigns 10.42.0.1 to the AP interface.
  static const String _hotspotIp = '10.42.0.1';
  static const int _aaTcpPort = 50001;

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

    _handoffProcess?.kill(ProcessSignal.sigterm);
    _handoffProcess = null;
    _engineStateSub?.cancel();
    _engineStateSub = null;
    AndroidAutoEngine().stopSession();

    if (!Platform.isWindows) {
      try {
        await Process.run('sudo', ['nmcli', 'connection', 'down', _hotspotConnectionName]);
        await Process.run('bluetoothctl', ['discoverable', 'off']);
        await Process.run('bluetoothctl', ['pairable', 'off']);
      } catch (e) {
        if (kDebugMode) print('[WirelessAABridge] Cleanup error: $e');
      }
    }

    _emit(AAConnectionStep.idle, 'Disconnected');
  }

  /// Forward a touch input event to the native AA engine (Channel 4).
  void sendTouchEvent(double normalizedX, double normalizedY, int action) {
    // action: 0=DOWN, 1=MOVE, 2=UP
    AndroidAutoEngine().sendTouchEvent(x: normalizedX, y: normalizedY, action: action);
  }

  // ── Linux native flow ────────────────────────────────────────────────────

  Future<void> _runLinuxNative() async {
    try {
      // Step 1: Wi-Fi hotspot
      _emit(AAConnectionStep.hotspotCreating, 'Creating Wi-Fi hotspot…');
      await _createHotspot();

      // Step 2: Bind the native protocol socket up front, so the port is
      // already listening by the time the phone is handed the credentials.
      final bound = await AndroidAutoEngine().connectNativeSocket(port: _aaTcpPort);
      if (!bound) {
        throw Exception('Could not bind Android Auto TCP port $_aaTcpPort');
      }

      // The engine's socket accept is what actually marks the session live —
      // surface that to the wizard as the streaming step.
      _engineStateSub?.cancel();
      _engineStateSub = AndroidAutoEngine().stateStream.listen((state) {
        if (state == AAEngineState.streamingActive && _isRunning) {
          _emit(AAConnectionStep.streaming, 'Android Auto streaming',
              data: {'deviceName': 'Android Phone'});
        }
      });

      // Opportunistic wired path: if a phone is already plugged in over USB,
      // kick off the AOAP mode switch too.
      await AaUsbAoapService().checkForAndroidDeviceAndInitiateAoap();

      // Step 3: Bluetooth discoverable
      _emit(AAConnectionStep.bluetoothDiscoverable,
          'Waiting for Bluetooth pairing…',
          data: {'btName': _bluetoothAlias});
      await _makeBluetoothDiscoverable();

      // Step 4: Register the AA Wireless SDP profile + credential handshake
      // daemon. Its stdout events drive the remaining wizard steps. Note:
      // wireless AA has no user-visible app on the phone — pairing (or
      // re-pairing) via Bluetooth is what triggers the phone to connect.
      _emit(AAConnectionStep.waitingForPhone,
          'Pair your phone via Bluetooth: "$_bluetoothAlias" (re-pair if already paired)');
      await _launchBtHandoffDaemon();

    } catch (e) {
      _emit(AAConnectionStep.error, 'Connection failed: $e');
      _isRunning = false;
      if (kDebugMode) print('[WirelessAABridge] Fatal error: $e');
    }
  }

  /// Locates the handoff daemon script — repo-relative when running via
  /// `flutter run` from the project root, /usr/local/bin when installed as a
  /// kiosk appliance.
  String? _resolveHandoffScriptPath() {
    const candidates = [
      'scripts/aa_wireless_handoff.py',
      '/usr/local/bin/aa_wireless_handoff.py',
    ];
    for (final path in candidates) {
      if (File(path).existsSync()) return path;
    }
    return null;
  }

  Future<void> _launchBtHandoffDaemon() async {
    final scriptPath = _resolveHandoffScriptPath();
    if (scriptPath == null) {
      _emit(AAConnectionStep.error,
          'aa_wireless_handoff.py not found — run from the repo root or install it to /usr/local/bin');
      _isRunning = false;
      return;
    }

    _handoffProcess = await Process.start('python3', [
      scriptPath,
      '--ssid', _hotspotSsid,
      '--psk', _hotspotPassword,
      '--ip', _hotspotIp,
      '--port', '$_aaTcpPort',
    ]);

    _handoffProcess!.stdout.transform(const SystemEncoding().decoder).listen((chunk) {
      for (final line in chunk.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty) _handleHandoffLine(trimmed);
      }
    });

    _handoffProcess!.stderr.transform(const SystemEncoding().decoder).listen((line) {
      if (kDebugMode) print('[AAHandoff][err] $line');
    });

    // The daemon should outlive the whole session — an early exit while
    // we're still running means registration or the runtime died.
    _handoffProcess!.exitCode.then((code) {
      if (_isRunning && code != 0) {
        _emit(AAConnectionStep.error, 'Bluetooth handoff daemon exited (code $code)');
      }
    });
  }

  void _handleHandoffLine(String line) {
    if (kDebugMode) print('[AAHandoff] $line');
    if (!line.startsWith('EVENT:')) return;
    final event = line.substring('EVENT:'.length);

    if (event.startsWith('PHONE_CONNECTED')) {
      _emit(AAConnectionStep.tlsHandshake,
          'Phone connected — exchanging Wi-Fi credentials…');
    } else if (event.startsWith('CREDENTIALS_SENT')) {
      _emit(AAConnectionStep.channelDiscovery,
          'Phone joining hotspot & opening projection stream…');
    } else if (event.startsWith('PHONE_DISCONNECTED')) {
      // BT link dropping is normal once projection is streaming over Wi-Fi;
      // only treat it as a setback if the TCP session isn't up yet.
      if (!AndroidAutoEngine().isSessionActive) {
        _emit(AAConnectionStep.waitingForPhone,
            'Bluetooth dropped — reconnect your phone to "$_bluetoothAlias"');
      }
    } else if (event.startsWith('ERROR')) {
      _emit(AAConnectionStep.error, event.substring('ERROR'.length).trim());
    }
  }

  Future<void> _createHotspot() async {
    // Check if the profile already exists; create it if not.
    final check = await Process.run('sudo', ['nmcli', 'connection', 'show', _hotspotConnectionName]);
    if (check.exitCode != 0) {
      final result = await Process.run('sudo', [
        'nmcli',
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

    final up = await Process.run('sudo', ['nmcli', 'connection', 'up', _hotspotConnectionName]);
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
