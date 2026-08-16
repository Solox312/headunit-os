import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/projection_state.dart';
import '../services/android_auto_engine.dart';
import '../services/projection_bridge.dart';
import '../services/usb_hotplug_service.dart';
import '../services/wireless_aa_bridge.dart';
import '../services/audio_routing_service.dart';

class ProjectionProvider extends ChangeNotifier {
  ProjectionState _state = const ProjectionState();
  StreamSubscription<AAConnectionEvent>? _aaEventSub;
  StreamSubscription<UsbHotplugEvent>? _usbHotplugSub;
  Timer? _usbPollTimer;
  bool _isUsbConnected = false;

  bool get isUsbConnected => _isUsbConnected;

  ProjectionProvider() {
    UsbHotplugService().start();
    _usbHotplugSub = UsbHotplugService().events.listen(_onUsbHotplugEvent);
    checkInitialUsbState();

    // Poll sysfs every 1.5 seconds for instant USB plug/unplug UI updates
    _usbPollTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      checkInitialUsbState();
    });

    // Subscribe for the app's lifetime and keep the AA Wireless SDP profile
    // advertised from startup — the phone may initiate the connection at any
    // moment (e.g. right after pairing), not just while the wizard is open.
    _aaEventSub = WirelessAABridge().events.listen(_onAAEvent);
    WirelessAABridge().ensureHandoffDaemon();
  }

  Future<void> checkInitialUsbState() async {
    if (!Platform.isLinux) return;
    try {
      final sysDir = Directory('/sys/bus/usb/devices');
      if (await sysDir.exists()) {
        final entities = await sysDir.list().toList();
        bool foundPhone = false;
        for (final entity in entities) {
          final vendorFile = File('${entity.path}/idVendor');
          if (await vendorFile.exists()) {
            final vendor = (await vendorFile.readAsString()).trim();
            // Vendor IDs for mobile devices & AA/CarPlay accessories:
            // 18d1 = Google (Pixel/Nexus/AOAP)
            // 04e8 = Samsung
            // 22b8 = Motorola
            // 0bb4 = HTC
            // 2717 = Xiaomi
            // 1004 = LG
            // 05c6 = Qualcomm
            // 05ac = Apple iPhone / CarPlay dongles
            if (const ['18d1', '04e8', '22b8', '0bb4', '2717', '1004', '05c6', '05ac'].contains(vendor)) {
              foundPhone = true;
              break;
            }
          }
        }
        if (_isUsbConnected != foundPhone) {
          _isUsbConnected = foundPhone;
          notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) print('[ProjectionProvider] Error reading sysfs USB devices: $e');
    }
  }

  ProjectionState get state => _state;

  void setEngineType(ProjectionEngineType engineType) {
    _state = _state.copyWith(engineType: engineType);
    notifyListeners();
  }

  // ── Wireless Android Auto (no dongle) ────────────────────────────────────

  /// Begins the Wireless Android Auto connection flow (hotspot → Bluetooth →
  /// SDP handoff → native engine). Events arrive via the constructor's
  /// lifetime subscription.
  Future<void> startWirelessAndroidAuto() async {
    _state = _state.copyWith(
      mode: ProjectionMode.androidAuto,
      connectionType: ConnectionType.wireless,
      connectionStep: AAConnectionStep.hotspotCreating,
      isConnected: false,
      isStreaming: false,
    );
    notifyListeners();

    await AudioRoutingService().applyAudioRouting(AudioRoutingService().currentTarget);
    await WirelessAABridge().startWirelessAndroidAuto();
  }

  /// Tears down the active wireless session cleanly. The lifetime event
  /// subscription stays — the phone can re-initiate later.
  Future<void> stopWirelessAndroidAuto() async {
    await WirelessAABridge().stopWirelessAndroidAuto();

    _state = _state.copyWith(
      mode: ProjectionMode.disconnected,
      connectionStep: AAConnectionStep.idle,
      connectionType: ConnectionType.none,
      isConnected: false,
      isStreaming: false,
      deviceName: '',
    );
    notifyListeners();
  }

  void _onAAEvent(AAConnectionEvent event) {
    _state = _state.copyWith(connectionStep: event.step);

    switch (event.step) {
      case AAConnectionStep.streaming:
        // The phone can initiate without the wizard being open — make sure
        // the projection mode reflects the live session either way.
        _state = _state.copyWith(
          mode: ProjectionMode.androidAuto,
          connectionType: _state.connectionType == ConnectionType.none
              ? ConnectionType.wireless
              : _state.connectionType,
          isConnected: true,
          isStreaming: true,
          deviceName: event.data?['deviceName'] ?? 'Android Phone',
          phoneBatteryLevel: (event.data?['phoneBattery'] as int?) ?? 0,
          activeApp: 'Android Auto',
        );
        AudioRoutingService().applyAudioRouting(AudioRoutingService().currentTarget);
      case AAConnectionStep.idle:
      case AAConnectionStep.error:
        _state = _state.copyWith(
          isConnected: false,
          isStreaming: false,
        );
      default:
        break;
    }
    notifyListeners();
  }

  // ── ADB DHU wired debug mode ─────────────────────────────────────────────

  /// Connect to Android Auto Head Unit Server via ADB port forward (127.0.0.1:5277)
  Future<bool> connectAdbDhuServer({String host = '127.0.0.1', int port = 5277}) async {
    final engine = AndroidAutoEngine();
    final bool success = await engine.connectAdbDhuServer(host: host, port: port);

    if (success) {
      _state = _state.copyWith(
        mode: ProjectionMode.androidAuto,
        isConnected: true,
        isStreaming: true,
        deviceName: "Android Device (ADB DHU 5277)",
        connectionType: ConnectionType.wired,
        activeApp: "Android Auto",
      );
      await AudioRoutingService().applyAudioRouting(AudioRoutingService().currentTarget);
    } else {
      _state = _state.copyWith(
        mode: ProjectionMode.androidAuto,
        isConnected: false,
        isStreaming: false,
        deviceName: "ADB Connection Failed ($host:$port)",
      );
    }

    notifyListeners();
    return success;
  }

  // ── USB hotplug (wired Android Auto) ─────────────────────────────────────

  /// Reacts to a phone being physically plugged in/unplugged, reported by
  /// [UsbHotplugService]. Only jumps into wired Android Auto mode from an
  /// idle state — never interrupts an already-active wireless/CarPlay
  /// session just because some unrelated USB device was attached.
  void _onUsbHotplugEvent(UsbHotplugEvent event) {
    _isUsbConnected = event.attached;
    notifyListeners();

    if (event.attached) {
      if (_state.mode != ProjectionMode.disconnected) return;

      _state = _state.copyWith(
        mode: ProjectionMode.androidAuto,
        connectionType: ConnectionType.wired,
        connectionStep: AAConnectionStep.streaming,
        isConnected: true,
        isStreaming: true,
        deviceName: 'Android Device',
      );
      notifyListeners();

      if (kDebugMode) {
        print('[ProjectionProvider] USB hotplug attach -> entering wired Android Auto mode');
      }

      launchWiredAndroidAuto();
    } else if (_state.connectionType == ConnectionType.wired) {
      switchMode(ProjectionMode.disconnected);
    }
  }

  /// Hands the display over to openauto for a wired Android Auto session.
  Future<void> launchWiredAndroidAuto() async {
    if (!Platform.isLinux) return;
    await AudioRoutingService().applyAudioRouting(AudioRoutingService().currentTarget);
    if (kDebugMode) {
      print('[ProjectionProvider] Handing display over to openauto for full-screen Android Auto…');
    }
    final result = await Process.run(
        'sudo', ['systemctl', 'start', 'openauto.service']);
    if (result.exitCode != 0) {
      if (kDebugMode) {
        print('[ProjectionProvider] Display handover failed (${result.exitCode}): ${result.stderr}');
      }
    }
  }

  // ── Mode switching ───────────────────────────────────────────────────────

  void switchMode(ProjectionMode mode) {
    if (mode == ProjectionMode.disconnected) {
      if (_state.connectionType == ConnectionType.wireless) {
        stopWirelessAndroidAuto();
        return;
      }
      AndroidAutoEngine().stopSession();
      _state = _state.copyWith(
        mode: ProjectionMode.disconnected,
        isConnected: false,
        isStreaming: false,
        connectionType: ConnectionType.none,
        connectionStep: AAConnectionStep.idle,
      );
    } else if (mode == ProjectionMode.appleCarPlay) {
      ProjectionBridge().initializeBridge();
      _state = _state.copyWith(
        mode: ProjectionMode.appleCarPlay,
        isConnected: true,
        isStreaming: true,
        deviceName: "Apple CarPlay Device",
        connectionType: ConnectionType.usbDongle,
        activeApp: "CarPlay Stream",
      );
    } else if (mode == ProjectionMode.androidAuto) {
      _state = _state.copyWith(
        mode: ProjectionMode.androidAuto,
        connectionType: ConnectionType.wired,
        connectionStep: AAConnectionStep.streaming,
        isConnected: true,
        isStreaming: true,
        deviceName: "Android Auto",
      );
      launchWiredAndroidAuto();
      notifyListeners();
      return;
    }
    notifyListeners();
  }

  void setActiveApp(String appName) {
    _state = _state.copyWith(activeApp: appName);
    notifyListeners();
  }

  void handleTouchEvent(double dx, double dy, String eventType) {
    if (_state.connectionType == ConnectionType.wireless) {
      WirelessAABridge().sendTouchEvent(dx, dy, 0);
    } else {
      AndroidAutoEngine().sendTouchEvent(x: dx, y: dy, action: 0);
    }
    if (kDebugMode) {
      print("Projection Touch [$eventType]: ($dx, $dy)");
    }
  }

  @override
  void dispose() {
    _usbPollTimer?.cancel();
    _aaEventSub?.cancel();
    _usbHotplugSub?.cancel();
    super.dispose();
  }
}
