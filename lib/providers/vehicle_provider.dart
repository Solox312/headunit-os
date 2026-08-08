import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/vehicle_status.dart';
import '../services/settings_storage_service.dart';

class VehicleProvider extends ChangeNotifier {
  VehicleStatus _status = const VehicleStatus();
  String _driverName = "Change Me";
  Timer? _liveTelemetryTimer;
  final Random _random = Random();

  VehicleStatus get status => _status;
  String get driverName => _driverName;
  bool get isDefaultDriverName => _driverName == "Change Me";

  VehicleProvider() {
    _startLiveSimulation();
    _loadStoredDriverName();
  }

  Future<void> _loadStoredDriverName() async {
    _driverName = await SettingsStorageService().loadDriverName();
    notifyListeners();
  }

  Future<void> updateDriverName(String newName) async {
    final trimmed = newName.trim();
    _driverName = trimmed.isEmpty ? "Change Me" : trimmed;
    await SettingsStorageService().saveDriverName(_driverName);
    notifyListeners();
  }

  /// Returns timed greeting based on system hour ("Good Morning", "Good Afternoon", "Good Evening", "Good Night")
  String getTimedGreetingPrefix() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return "Good Morning";
    } else if (hour >= 12 && hour < 17) {
      return "Good Afternoon";
    } else if (hour >= 17 && hour < 21) {
      return "Good Evening";
    } else {
      return "Good Night";
    }
  }

  /// Returns full greeting string (e.g. "Good Morning, Change Me" or "Good Afternoon, Carl")
  String getTimedGreeting() {
    return "${getTimedGreetingPrefix()}, $_driverName";
  }

  void _startLiveSimulation() {
    _liveTelemetryTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_status.gear == DriveGear.D || _status.gear == DriveGear.S) {
        // Add subtle speed & RPM jitter to simulate real OBD-II driving telemetry
        double speedDelta = (_random.nextDouble() * 1.6) - 0.8;
        double newSpeed = (_status.speedMph + speedDelta).clamp(25.0, 75.0);
        double newRpm = 1200 + (newSpeed * 32) + ((_random.nextDouble() * 60) - 30);

        _status = _status.copyWith(
          speedMph: newSpeed,
          rpm: newRpm,
        );
        notifyListeners();
      }
    });
  }

  void setGear(DriveGear gear) {
    double targetSpeed = _status.speedMph;
    double targetRpm = _status.rpm;
    if (gear == DriveGear.P || gear == DriveGear.N) {
      targetSpeed = 0.0;
      targetRpm = 800.0;
    }
    _status = _status.copyWith(
      gear: gear,
      speedMph: targetSpeed,
      rpm: targetRpm,
    );
    notifyListeners();
  }

  void adjustClimateTemp(double delta) {
    double newTemp = (_status.targetClimateTempF + delta).clamp(60.0, 85.0);
    _status = _status.copyWith(targetClimateTempF: newTemp);
    notifyListeners();
  }

  void setFanSpeed(int level) {
    _status = _status.copyWith(fanSpeedLevel: level.clamp(1, 5));
    notifyListeners();
  }

  void toggleHeadlights() {
    _status = _status.copyWith(headlightsOn: !_status.headlightsOn);
    notifyListeners();
  }

  @override
  void dispose() {
    _liveTelemetryTimer?.cancel();
    super.dispose();
  }
}
