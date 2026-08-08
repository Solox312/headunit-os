import 'package:flutter/foundation.dart';
import '../models/projection_state.dart';
import '../services/android_auto_engine.dart';

class ProjectionProvider extends ChangeNotifier {
  ProjectionState _state = const ProjectionState();

  ProjectionState get state => _state;

  void setEngineType(ProjectionEngineType engineType) {
    _state = _state.copyWith(engineType: engineType);
    notifyListeners();
  }

  /// Connect to ADB Forwarded Android Auto Head Unit Server (127.0.0.1:5277)
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

  void switchMode(ProjectionMode mode) {
    if (mode == ProjectionMode.disconnected) {
      AndroidAutoEngine().stopSession();
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
      // Trigger ADB DHU server connection attempt
      connectAdbDhuServer();
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
    AndroidAutoEngine().sendTouchEvent(x: dx, y: dy, action: 0);
    if (kDebugMode) {
      print("Projection Touch [$eventType]: ($dx, $dy)");
    }
  }
}
