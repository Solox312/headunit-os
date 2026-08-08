import 'package:flutter/foundation.dart';
import '../models/projection_state.dart';

class ProjectionProvider extends ChangeNotifier {
  ProjectionState _state = const ProjectionState();

  ProjectionState get state => _state;

  void setEngineType(ProjectionEngineType engineType) {
    _state = _state.copyWith(engineType: engineType);
    notifyListeners();
  }

  void switchMode(ProjectionMode mode) {
    if (mode == ProjectionMode.disconnected) {
      _state = _state.copyWith(
        mode: ProjectionMode.disconnected,
        isConnected: false,
        isStreaming: false,
        connectionType: ConnectionType.none,
      );
    } else if (mode == ProjectionMode.appleCarPlay) {
      _state = _state.copyWith(
        mode: ProjectionMode.appleCarPlay,
        isConnected: true,
        isStreaming: true,
        deviceName: "iPhone 15 Pro",
        connectionType: ConnectionType.wireless,
        activeApp: "Apple Maps",
      );
    } else if (mode == ProjectionMode.androidAuto) {
      _state = _state.copyWith(
        mode: ProjectionMode.androidAuto,
        isConnected: true,
        isStreaming: true,
        deviceName: "Google Pixel 8 Pro",
        connectionType: ConnectionType.wireless,
        activeApp: "Google Maps",
      );
    } else if (mode == ProjectionMode.simulator) {
      _state = _state.copyWith(
        mode: ProjectionMode.simulator,
        isConnected: true,
        isStreaming: true,
        deviceName: "Projection Simulator",
        connectionType: ConnectionType.simulator,
        activeApp: "Simulated Projection",
      );
    }
    notifyListeners();
  }

  void setActiveApp(String appName) {
    _state = _state.copyWith(activeApp: appName);
    notifyListeners();
  }

  void handleTouchEvent(double dx, double dy, String eventType) {
    // Touch coordinates (x, y) normalized 0.0 - 1.0 sent to USB Dongle / projection stream daemon
    if (kDebugMode) {
      print("Projection Touch [$eventType]: ($dx, $dy)");
    }
  }
}
