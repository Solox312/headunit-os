import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/automotive_colors.dart';
import '../models/projection_state.dart';
import '../providers/projection_provider.dart';

class ProjectionSimulatorCanvas extends StatefulWidget {
  const ProjectionSimulatorCanvas({super.key});

  @override
  State<ProjectionSimulatorCanvas> createState() => _ProjectionSimulatorCanvasState();
}

class _ProjectionSimulatorCanvasState extends State<ProjectionSimulatorCanvas> {
  String _selectedSimApp = "Maps";

  @override
  Widget build(BuildContext context) {
    final projection = Provider.of<ProjectionProvider>(context);
    final state = projection.state;
    final isCarPlay = state.mode == ProjectionMode.appleCarPlay;

    return Container(
      decoration: BoxDecoration(
        color: isCarPlay ? const Color(0xFF1C1C1E) : const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCarPlay ? AutomotiveColors.carPlayColor : AutomotiveColors.androidAutoColor,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: GestureDetector(
          onTapDown: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final Offset localPos = box.globalToLocal(details.globalPosition);
            final double normalizedX = (localPos.dx / box.size.width).clamp(0.0, 1.0);
            final double normalizedY = (localPos.dy / box.size.height).clamp(0.0, 1.0);
            projection.handleTouchEvent(normalizedX, normalizedY, "TAP_DOWN");
          },
          child: Stack(
            children: [
              // Active App Canvas Content
              _buildAppBody(state),

              // Header Status Bar (CarPlay / Android Auto style)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.black.withValues(alpha: 0.55),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCarPlay ? AutomotiveColors.carPlayColor : AutomotiveColors.androidAutoColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isCarPlay ? "CarPlay" : "Android Auto",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        state.deviceName,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const Spacer(),
                      Icon(
                        state.connectionType == ConnectionType.wireless
                            ? Icons.wifi_rounded
                            : Icons.usb_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${state.phoneBatteryLevel}%",
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.battery_5_bar_rounded, color: Colors.greenAccent, size: 18),
                    ],
                  ),
                ),
              ),

              // Bottom App Switcher Dock (CarPlay/AA Home Bar)
              Positioned(
                bottom: 12,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSimAppButton("Maps", Icons.map_rounded, Colors.green),
                      _buildSimAppButton("Music", Icons.music_note_rounded, Colors.pinkAccent),
                      _buildSimAppButton("Phone", Icons.phone_rounded, Colors.blue),
                      _buildSimAppButton("Messages", Icons.chat_rounded, Colors.orangeAccent),
                      _buildSimAppButton("Waze", Icons.navigation_rounded, Colors.cyan),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimAppButton(String name, IconData icon, Color color) {
    final bool isSelected = _selectedSimApp == name;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedSimApp = name;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.transparent),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Widget _buildAppBody(ProjectionState state) {
    if (_selectedSimApp == "Maps" || _selectedSimApp == "Waze") {
      return Container(
        color: const Color(0xFF1E293B),
        child: Stack(
          children: [
            // Map Grid Background simulation
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.navigation_rounded, size: 64, color: AutomotiveColors.cyanAccent),
                  const SizedBox(height: 12),
                  Text(
                    "Turn Right on Grand Ave in 300 ft",
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "ETA: 14 mins • 5.8 mi remaining",
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (_selectedSimApp == "Music") {
      return Container(
        color: const Color(0xFF0F172A),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(colors: [Colors.purpleAccent, Colors.blueAccent]),
                  boxShadow: const [BoxShadow(color: Colors.purpleAccent, blurRadius: 20)],
                ),
                child: const Icon(Icons.album_rounded, size: 80, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                "Starboy - The Weeknd",
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.skip_previous_rounded, size: 36, color: Colors.white70),
                  SizedBox(width: 24),
                  Icon(Icons.pause_circle_filled_rounded, size: 48, color: Colors.white),
                  SizedBox(width: 24),
                  Icon(Icons.skip_next_rounded, size: 36, color: Colors.white70),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      return Container(
        color: const Color(0xFF111827),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.apps_rounded, size: 48, color: Colors.white70),
              const SizedBox(height: 12),
              Text(
                "$_selectedSimApp App Active",
                style: GoogleFonts.inter(fontSize: 18, color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }
  }
}
