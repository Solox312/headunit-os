import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/automotive_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/gauge_widget.dart';
import '../providers/vehicle_provider.dart';
import '../models/vehicle_status.dart';

class VehicleScreen extends StatelessWidget {
  const VehicleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vehicle = Provider.of<VehicleProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Left Column: Dual Gauges (Speed & RPM Tachometer)
            Expanded(
              flex: 6,
              child: GlassCard(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GaugeWidget(
                          value: vehicle.status.speedMph,
                          minValue: 0,
                          maxValue: 140,
                          title: "Speed",
                          unit: "MPH",
                          accentColor: AutomotiveColors.electricCyan,
                          size: 190,
                        ),
                        GaugeWidget(
                          value: vehicle.status.rpm,
                          minValue: 0,
                          maxValue: 8000,
                          title: "Engine",
                          unit: "RPM",
                          accentColor: vehicle.status.rpm > 5500 ? AutomotiveColors.redAccent : AutomotiveColors.dongleViolet,
                          size: 190,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Gear Selection Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: DriveGear.values.map((gear) {
                        final bool isSelected = vehicle.status.gear == gear;
                        return InkWell(
                          onTap: () => vehicle.setGear(gear),
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AutomotiveColors.electricCyan : AutomotiveColors.glassPanel,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? AutomotiveColors.electricCyan : AutomotiveColors.stroke,
                              ),
                            ),
                            child: Text(
                              gear.name,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.black : AutomotiveColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Right Column: Climate Control & Tire Pressure Monitor
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  // Climate Control Card
                  Expanded(
                    child: GlassCard(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "CLIMATE CONTROL",
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AutomotiveColors.textSecondary,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline_rounded),
                                iconSize: 36,
                                color: AutomotiveColors.electricCyan,
                                onPressed: () => vehicle.adjustClimateTemp(-1.0),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "${vehicle.status.targetClimateTempF.toInt()}°F",
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AutomotiveColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline_rounded),
                                iconSize: 36,
                                color: AutomotiveColors.redAccent,
                                onPressed: () => vehicle.adjustClimateTemp(1.0),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: Icon(Icons.ac_unit_rounded,
                                    color: vehicle.status.headlightsOn ? AutomotiveColors.electricCyan : AutomotiveColors.textMuted),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: Icon(Icons.light_mode_rounded,
                                    color: vehicle.status.headlightsOn ? AutomotiveColors.electricCyan : AutomotiveColors.textMuted),
                                onPressed: () => vehicle.toggleHeadlights(),
                              ),
                              IconButton(
                                icon: const Icon(Icons.air_rounded, color: AutomotiveColors.electricCyan),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tire Pressure & Battery Voltage Card
                  GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildVehicleTile(
                          icon: Icons.tire_repair_rounded,
                          title: "TIRES",
                          value: "${vehicle.status.tirePressurePsi.toInt()} PSI",
                          color: AutomotiveColors.nativeGreen,
                        ),
                        _buildVehicleTile(
                          icon: Icons.battery_charging_full_rounded,
                          title: "BATTERY",
                          value: "${vehicle.status.batteryVoltage} V",
                          color: AutomotiveColors.electricCyan,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: AutomotiveColors.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AutomotiveColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
