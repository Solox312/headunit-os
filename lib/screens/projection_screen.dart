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
    final mode = projection.state.mode;

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
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AutomotiveColors.textPrimary,
                    letterSpacing: -0.3,
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
                  label: "Android Auto (DHU 5277)",
                  mode: ProjectionMode.androidAuto,
                  activeColor: AutomotiveColors.androidAutoColor,
                  icon: Icons.phone_android_rounded,
                ),
                const SizedBox(width: 8),
                _buildModeChip(
                  context,
                  label: "Simulator Mode",
                  mode: ProjectionMode.simulator,
                  activeColor: AutomotiveColors.electricCyan,
                  icon: Icons.computer_rounded,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Main Video Stream Viewport
            Expanded(
              child: mode == ProjectionMode.disconnected
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
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : AutomotiveColors.textSecondary),
      label: Text(label),
      selected: isSelected,
      selectedColor: activeColor,
      backgroundColor: AutomotiveColors.glassPanel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isSelected ? activeColor : AutomotiveColors.stroke),
      ),
      labelStyle: GoogleFonts.inter(
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
        color: AutomotiveColors.glassPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AutomotiveColors.stroke),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.usb_off_rounded, size: 64, color: AutomotiveColors.textMuted),
            const SizedBox(height: 16),
            Text(
              "No Phone Connected",
              style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.bold, color: AutomotiveColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              "Plug in your phone via USB Dongle, connect via Wireless Hotspot, or start Head Unit Server on your phone.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: AutomotiveColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.adb_rounded),
                  label: Text("Connect ADB DHU (Port 5277)", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AutomotiveColors.androidAutoColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    await projection.connectAdbDhuServer();
                  },
                ),
                const SizedBox(width: 14),
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text("Launch Simulator", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AutomotiveColors.electricCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    projection.switchMode(ProjectionMode.simulator);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
