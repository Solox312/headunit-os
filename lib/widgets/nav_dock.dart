import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../theme/automotive_colors.dart';
import '../providers/projection_provider.dart';
import '../models/projection_state.dart';

class NavDock extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const NavDock({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  State<NavDock> createState() => _NavDockState();
}

class _NavDockState extends State<NavDock> {
  late String _currentTime;
  Timer? _timeTimer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _currentTime = DateFormat('h:mm a').format(DateTime.now());
      });
    }
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projection = Provider.of<ProjectionProvider>(context);

    return Container(
      width: 96,
      decoration: const BoxDecoration(
        color: Color(0xFF090C12),
        border: Border(
          right: BorderSide(color: AutomotiveColors.cardBorder, width: 1.5),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Vehicle Logo / Home Icon
          IconButton(
            iconSize: 32,
            icon: const Icon(Icons.drive_eta_rounded, color: AutomotiveColors.cyanAccent),
            onPressed: () => widget.onDestinationSelected(0), // Home
          ),
          const SizedBox(height: 8),
          Text(
            _currentTime,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AutomotiveColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AutomotiveColors.cardBorder, height: 1, indent: 12, endIndent: 12),
          const SizedBox(height: 16),

          // Main Navigation Items
          Expanded(
            child: Column(
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.dashboard_rounded,
                  label: "Home",
                ),
                const SizedBox(height: 16),
                _buildNavItem(
                  index: 1,
                  icon: Icons.phone_android_rounded,
                  label: projection.state.mode == ProjectionMode.appleCarPlay
                      ? "CarPlay"
                      : (projection.state.mode == ProjectionMode.androidAuto ? "AA Stream" : "Projection"),
                  badgeColor: projection.state.mode == ProjectionMode.appleCarPlay
                      ? AutomotiveColors.carPlayColor
                      : (projection.state.mode == ProjectionMode.androidAuto
                          ? AutomotiveColors.androidAutoColor
                          : AutomotiveColors.cyanAccent),
                ),
                const SizedBox(height: 16),
                _buildNavItem(
                  index: 2,
                  icon: Icons.music_note_rounded,
                  label: "Media",
                ),
                const SizedBox(height: 16),
                _buildNavItem(
                  index: 3,
                  icon: Icons.speed_rounded,
                  label: "Gauges",
                ),
                const SizedBox(height: 16),
                _buildNavItem(
                  index: 4,
                  icon: Icons.settings_rounded,
                  label: "Settings",
                ),
              ],
            ),
          ),

          // Voice Assistant / Siri / Google Assistant Button
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Voice Assistant Triggered (Siri / Google Assistant)"),
                    duration: Duration(seconds: 2),
                    backgroundColor: AutomotiveColors.cyanAccent,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AutomotiveColors.cyanAccent, AutomotiveColors.blueAccent],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AutomotiveColors.cyanAccent.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: Colors.black,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    Color? badgeColor,
  }) {
    final bool isSelected = widget.selectedIndex == index;

    return InkWell(
      onTap: () => widget.onDestinationSelected(index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        height: 64,
        decoration: BoxDecoration(
          color: isSelected ? (badgeColor ?? AutomotiveColors.cyanAccent).withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? (badgeColor ?? AutomotiveColors.cyanAccent) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? (badgeColor ?? AutomotiveColors.cyanAccent)
                  : AutomotiveColors.textSecondary,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? AutomotiveColors.textPrimary
                    : AutomotiveColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
