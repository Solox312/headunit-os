import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/automotive_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/gauge_widget.dart';
import '../providers/vehicle_provider.dart';
import '../providers/media_provider.dart';
import '../providers/projection_provider.dart';
import '../models/projection_state.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onOpenProjection;

  const DashboardScreen({super.key, required this.onOpenProjection});

  @override
  Widget build(BuildContext context) {
    final vehicle = Provider.of<VehicleProvider>(context);
    final media = Provider.of<MediaProvider>(context);
    final projection = Provider.of<ProjectionProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Left Column: Speedometer & Telemetry Widget
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  Expanded(
                    child: GlassCard(
                      child: Center(
                        child: GaugeWidget(
                          value: vehicle.status.speedMph,
                          minValue: 0,
                          maxValue: 140,
                          title: "Speed",
                          unit: "MPH",
                          accentColor: AutomotiveColors.cyanAccent,
                          size: 210,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Quick OBD-II Telemetry Bar
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickMetric("RPM", vehicle.status.rpm.toInt().toString(), "rpm", AutomotiveColors.blueAccent),
                        _buildQuickMetric("GEAR", vehicle.status.gear.name, "", AutomotiveColors.cyanAccent),
                        _buildQuickMetric("COOLANT", "${vehicle.status.coolantTempF.toInt()}°", "F", AutomotiveColors.orangeAccent),
                        _buildQuickMetric("FUEL", "${vehicle.status.fuelPercent.toInt()}%", "", AutomotiveColors.greenAccent),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Right Column: CarPlay/Android Auto Card + Media Player Card
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  // Projection Status & Quick Viewport Card
                  Expanded(
                    flex: 5,
                    child: GlassCard(
                      onTap: onOpenProjection,
                      borderColor: projection.state.mode == ProjectionMode.appleCarPlay
                          ? AutomotiveColors.carPlayColor
                          : (projection.state.mode == ProjectionMode.androidAuto
                              ? AutomotiveColors.androidAutoColor
                              : AutomotiveColors.cyanAccent),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  projection.state.mode == ProjectionMode.appleCarPlay
                                      ? Icons.phone_iphone_rounded
                                      : Icons.phone_android_rounded,
                                  size: 44,
                                  color: projection.state.mode == ProjectionMode.appleCarPlay
                                      ? AutomotiveColors.carPlayColor
                                      : AutomotiveColors.androidAutoColor,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  projection.state.mode == ProjectionMode.appleCarPlay
                                      ? "Apple CarPlay Active"
                                      : (projection.state.mode == ProjectionMode.androidAuto
                                          ? "Android Auto Active"
                                          : "Projection Disconnected"),
                                  style: GoogleFonts.orbitron(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Connected to ${projection.state.deviceName} • Tap to view full stream",
                                  style: GoogleFonts.inter(fontSize: 12, color: AutomotiveColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.greenAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text("LIVE", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick Media Control Card
                  Expanded(
                    flex: 4,
                    child: GlassCard(
                      child: Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AutomotiveColors.surfaceGlass,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                media.mediaItem.coverUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AutomotiveColors.cardBackground,
                                    child: const Icon(
                                      Icons.album_rounded,
                                      size: 40,
                                      color: AutomotiveColors.purpleAccent,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  media.mediaItem.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  media.mediaItem.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(fontSize: 13, color: AutomotiveColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.skip_previous_rounded),
                                iconSize: 32,
                                onPressed: () => media.previousTrack(),
                              ),
                              IconButton(
                                icon: Icon(media.mediaItem.isPlaying
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_fill_rounded),
                                iconSize: 42,
                                color: AutomotiveColors.cyanAccent,
                                onPressed: () => media.togglePlayPause(),
                              ),
                              IconButton(
                                icon: const Icon(Icons.skip_next_rounded),
                                iconSize: 32,
                                onPressed: () => media.nextTrack(),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildQuickMetric(String label, String value, String unit, Color color) {
    return Expanded(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AutomotiveColors.textMuted),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 2),
                  Text(unit, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
