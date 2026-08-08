import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/automotive_colors.dart';
import '../models/projection_state.dart';
import '../providers/projection_provider.dart';
import '../widgets/projection_simulator_canvas.dart';

class ProjectionScreen extends StatelessWidget {
  const ProjectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projection = Provider.of<ProjectionProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top Control Bar: Mode Toggle (Apple CarPlay vs Android Auto vs Simulator vs Disconnect)
            Row(
              children: [
                Text(
                  "PROJECTION STREAM",
                  style: GoogleFonts.orbitron(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AutomotiveColors.textPrimary,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                _buildModeChip(
                  context,
                  label: "Apple CarPlay",
                  mode: ProjectionMode.appleCarPlay,
                  activeColor: AutomotiveColors.carPlayColor,
                  icon: Icons.phone_iphone_rounded,
                ),
                const SizedBox(width: 8),
                _buildModeChip(
                  context,
                  label: "Android Auto",
                  mode: ProjectionMode.androidAuto,
                  activeColor: AutomotiveColors.androidAutoColor,
                  icon: Icons.phone_android_rounded,
                ),
                const SizedBox(width: 8),
                _buildModeChip(
                  context,
                  label: "Simulator Mode",
                  mode: ProjectionMode.simulator,
                  activeColor: AutomotiveColors.cyanAccent,
                  icon: Icons.computer_rounded,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Main Video Stream / Simulator Viewport
            Expanded(
              child: projection.state.mode == ProjectionMode.disconnected
                  ? _buildDisconnectedState(context, projection)
                  : const ProjectionSimulatorCanvas(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeChip(
    BuildContext context, {
    required String label,
    required ProjectionMode mode,
    required Color activeColor,
    required IconData icon,
  }) {
    final projection = Provider.of<ProjectionProvider>(context, listen: false);
    final isSelected = projection.state.mode == mode;

    return ChoiceChip(
      avatar: Icon(icon, size: 18, color: isSelected ? Colors.white : AutomotiveColors.textSecondary),
      label: Text(label),
      selected: isSelected,
      selectedColor: activeColor,
      backgroundColor: AutomotiveColors.cardBackground,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AutomotiveColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) {
          projection.switchMode(mode);
        }
      },
    );
  }

  Widget _buildDisconnectedState(BuildContext context, ProjectionProvider projection) {
    return Container(
      decoration: BoxDecoration(
        color: AutomotiveColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AutomotiveColors.cardBorder),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.usb_off_rounded, size: 64, color: AutomotiveColors.textMuted),
            const SizedBox(height: 16),
            Text(
              "No Phone Connected",
              style: GoogleFonts.orbitron(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              "Plug in your iPhone or Android phone via USB Dongle or connect via Wireless Hotspot.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: AutomotiveColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text("Launch Projection Simulator"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AutomotiveColors.cyanAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                projection.switchMode(ProjectionMode.simulator);
              },
            ),
          ],
        ),
      ),
    );
  }
}
