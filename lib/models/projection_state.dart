/// Android Auto wireless connection lifecycle steps.
enum AAConnectionStep {
  idle,
  hotspotCreating,
  bluetoothDiscoverable,
  waitingForPhone,
  tlsHandshake,
  channelDiscovery,
  streaming,
  error,
}

enum ProjectionMode {
  disconnected,
  appleCarPlay,
  androidAuto,
}

enum ConnectionType {
  none,
  wireless,
  usbDongle,
  wired,
  adbDhu,
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
  final AAConnectionStep connectionStep;
  final String hotspotSsid;
  final String wirelessIp;
  final int signalStrength;

  const ProjectionState({
    this.mode = ProjectionMode.disconnected,
    this.connectionType = ConnectionType.none,
    this.engineType = ProjectionEngineType.autoDetect,
    this.deviceName = "",
    this.phoneBatteryLevel = 0,
    this.isConnected = false,
    this.isStreaming = false,
    this.activeApp = "",
    this.fps = 0,
    this.connectionStep = AAConnectionStep.idle,
    this.hotspotSsid = "HeadUnit-OS",
    this.wirelessIp = "",
    this.signalStrength = 0,
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
    AAConnectionStep? connectionStep,
    String? hotspotSsid,
    String? wirelessIp,
    int? signalStrength,
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
      connectionStep: connectionStep ?? this.connectionStep,
      hotspotSsid: hotspotSsid ?? this.hotspotSsid,
      wirelessIp: wirelessIp ?? this.wirelessIp,
      signalStrength: signalStrength ?? this.signalStrength,
    );
  }
}
