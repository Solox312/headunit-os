enum ProjectionMode {
  disconnected,
  appleCarPlay,
  androidAuto,
  simulator,
}

enum ConnectionType {
  none,
  wireless,
  usbDongle,
  wired,
  adbDhu,
  simulator,
}

enum ProjectionEngineType {
  autoDetect,        // Auto-detects hardware dongle or native software
  carlinkitHardware, // USB Hardware Dongle (Carlinkit CPC200)
  nativeSoftware,    // 100% Native RPi Wireless (Bluetooth + 5GHz Wi-Fi)
}

class ProjectionState {
  final ProjectionMode mode;
  final ConnectionType connectionType;
  final ProjectionEngineType engineType;
  final String deviceName;
  final int phoneBatteryLevel;
  final bool isConnected;
  final bool isStreaming;
  final String activeApp;
  final int fps;

  const ProjectionState({
    this.mode = ProjectionMode.appleCarPlay,
    this.connectionType = ConnectionType.wireless,
    this.engineType = ProjectionEngineType.autoDetect,
    this.deviceName = "iPhone 15 Pro",
    this.phoneBatteryLevel = 88,
    this.isConnected = true,
    this.isStreaming = true,
    this.activeApp = "Maps",
    this.fps = 60,
  });

  ProjectionState copyWith({
    ProjectionMode? mode,
    ConnectionType? connectionType,
    ProjectionEngineType? engineType,
    String? deviceName,
    int? phoneBatteryLevel,
    bool? isConnected,
    bool? isStreaming,
    String? activeApp,
    int? fps,
  }) {
    return ProjectionState(
      mode: mode ?? this.mode,
      connectionType: connectionType ?? this.connectionType,
      engineType: engineType ?? this.engineType,
      deviceName: deviceName ?? this.deviceName,
      phoneBatteryLevel: phoneBatteryLevel ?? this.phoneBatteryLevel,
      isConnected: isConnected ?? this.isConnected,
      isStreaming: isStreaming ?? this.isStreaming,
      activeApp: activeApp ?? this.activeApp,
      fps: fps ?? this.fps,
    );
  }
}
