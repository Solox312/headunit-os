enum DriveGear { P, R, N, D, S }

class VehicleStatus {
  final double speedMph;
  final double rpm;
  final DriveGear gear;
  final double coolantTempF;
  final double fuelPercent;
  final double batteryVoltage;
  final double tirePressurePsi;
  final double targetClimateTempF;
  final int fanSpeedLevel;
  final bool headlightsOn;
  final bool highBeamsOn;
  final bool seatbeltBuckled;

  const VehicleStatus({
    this.speedMph = 45.0,
    this.rpm = 2200.0,
    this.gear = DriveGear.D,
    this.coolantTempF = 195.0,
    this.fuelPercent = 78.0,
    this.batteryVoltage = 14.2,
    this.tirePressurePsi = 35.0,
    this.targetClimateTempF = 70.0,
    this.fanSpeedLevel = 3,
    this.headlightsOn = true,
    this.highBeamsOn = false,
    this.seatbeltBuckled = true,
  });

  VehicleStatus copyWith({
    double? speedMph,
    double? rpm,
    DriveGear? gear,
    double? coolantTempF,
    double? fuelPercent,
    double? batteryVoltage,
    double? tirePressurePsi,
    double? targetClimateTempF,
    int? fanSpeedLevel,
    bool? headlightsOn,
    bool? highBeamsOn,
    bool? seatbeltBuckled,
  }) {
    return VehicleStatus(
      speedMph: speedMph ?? this.speedMph,
      rpm: rpm ?? this.rpm,
      gear: gear ?? this.gear,
      coolantTempF: coolantTempF ?? this.coolantTempF,
      fuelPercent: fuelPercent ?? this.fuelPercent,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      tirePressurePsi: tirePressurePsi ?? this.tirePressurePsi,
      targetClimateTempF: targetClimateTempF ?? this.targetClimateTempF,
      fanSpeedLevel: fanSpeedLevel ?? this.fanSpeedLevel,
      headlightsOn: headlightsOn ?? this.headlightsOn,
      highBeamsOn: highBeamsOn ?? this.highBeamsOn,
      seatbeltBuckled: seatbeltBuckled ?? this.seatbeltBuckled,
    );
  }
}
