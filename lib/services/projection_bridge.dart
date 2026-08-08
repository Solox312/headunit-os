import 'dart:async';
import 'package:flutter/foundation.dart';

/// ProjectionBridge provides the native connection interface between Flutter UI and
/// external protocol daemons (Carlinkit USB dongle driver / OpenAuto AASDK service).
class ProjectionBridge {
  static final ProjectionBridge _instance = ProjectionBridge._internal();
  factory ProjectionBridge() => _instance;
  ProjectionBridge._internal();

  bool _isDongleConnected = false;
  final StreamController<Uint8List> _videoFrameController = StreamController<Uint8List>.broadcast();

  Stream<Uint8List> get videoFrameStream => _videoFrameController.stream;
  bool get isDongleConnected => _isDongleConnected;

  /// Initializes USB Dongle monitoring via libusb / udev on Linux Raspberry Pi
  Future<void> initializeBridge() async {
    if (kDebugMode) {
      print("[ProjectionBridge] Initializing Linux USB Dongle & Protocol Listener...");
    }
    // In production on RPi, connects to Unix Socket / TCP socket / FFI exported by dongle daemon
    _isDongleConnected = true;
  }

  /// Send multi-touch coordinate to active projection stream
  void sendTouchCoordinate(double x, double y, int action) {
    // action: 0 = DOWN, 1 = MOVE, 2 = UP
    if (kDebugMode) {
      print("[ProjectionBridge] Sending Touch Event to Dongle: X=$x, Y=$y, Action=$action");
    }
  }

  /// Request key event (Home button, Siri / Assistant trigger, Media Next/Prev)
  void sendHardwareKey(String key) {
    if (kDebugMode) {
      print("[ProjectionBridge] Sending Hardware Key: $key");
    }
  }
}
