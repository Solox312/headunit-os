import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/vehicle_status.dart';

class VehicleProvider extends ChangeNotifier {
  VehicleStatus _status = const VehicleStatus();
  Timer? _liveTelemetryTimer;
  final Random _random = Random();

  VehicleStatus get status => _status;

  VehicleProvider() {
    _startLiveSimulation();
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
