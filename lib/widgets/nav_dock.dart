import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../theme/automotive_colors.dart';
import '../providers/projection_provider.dart';
import '../providers/wifi_provider.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/time_date_provider.dart';
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
  DateTime _now = DateTime.now();
  Timer? _timeTimer;

  @override
  void initState() {
    super.initState();
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
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
      width: 98,
      decoration: const BoxDecoration(
        color: AutomotiveColors.background,
        border: Border(
          right: BorderSide(color: AutomotiveColors.strokeSoft, width: 1.0),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Brand Logo Badge & Wordmark
          InkWell(
            onTap: () => widget.onDestinationSelected(0),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AutomotiveColors.glassPanel,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AutomotiveColors.stroke, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: AutomotiveColors.electricCyan.withValues(alpha: 0.2),
                    blurRadius: 16,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.directions_car_filled_rounded,
                color: AutomotiveColors.electricCyan,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "HeadUnit OS",
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AutomotiveColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          // Data Monospace Clock
          Consumer<TimeDateProvider>(
            builder: (context, timeDate, _) {
              return Text(
                timeDate.formatTime(_now, withSeconds: false),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AutomotiveColors.textSecondary,
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          // Status Indicators Row (Wi-Fi & Bluetooth)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Consumer<WifiProvider>(
                builder: (context, wifi, child) {
                  final bool isConnected = wifi.isConnected;
                  return Tooltip(
                    message: isConnected ? "Wi-Fi Connected: ${wifi.connectedSsid}" : "Wi-Fi Disconnected",
                    child: InkWell(
                      onTap: () => widget.onDestinationSelected(4), // Settings
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Icon(
                          isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                          color: isConnected ? AutomotiveColors.nativeGreen : AutomotiveColors.textMuted,
                          size: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
              Consumer<BluetoothProvider>(
                builder: (context, bt, child) {
                  final bool isConnected = bt.connectedDevice != null;
                  return Tooltip(
                    message: isConnected ? "Bluetooth Connected: ${bt.connectedDevice!.name}" : "Bluetooth Disconnected",
                    child: InkWell(
                      onTap: () => widget.onDestinationSelected(3), // Bluetooth Screen
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Icon(
                          isConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_disabled_rounded,
                          color: isConnected ? AutomotiveColors.electricCyan : AutomotiveColors.textMuted,
                          size: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AutomotiveColors.strokeSoft, height: 1, indent: 14, endIndent: 14),
          const SizedBox(height: 12),

          // Main Navigation Items (64px Automotive Touch Area)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.grid_view_rounded,
                    label: "Home",
                  ),
                  const SizedBox(height: 12),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.layers_rounded,
                    label: projection.state.mode == ProjectionMode.appleCarPlay
                        ? "CarPlay"
                        : (projection.state.mode == ProjectionMode.androidAuto ? "AA Stream" : "App Connect"),
                    badgeColor: projection.state.mode == ProjectionMode.appleCarPlay
                        ? AutomotiveColors.carPlayColor
                        : (projection.state.mode == ProjectionMode.androidAuto
                            ? AutomotiveColors.androidAutoColor
                            : AutomotiveColors.electricCyan),
                  ),
                  const SizedBox(height: 12),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.headphones_rounded,
                    label: "Media",
                  ),
                  const SizedBox(height: 12),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.bluetooth_rounded,
                    label: "Bluetooth",
                  ),
                  const SizedBox(height: 12),
                  _buildNavItem(
                    index: 4,
                    icon: Icons.settings_rounded,
                    label: "Settings",
                  ),
                ],
              ),
            ),
          ),

          // Voice Assistant / Siri / Google Assistant 52px Badge Button
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Voice Assistant Triggered (Siri / Google Assistant)",
                      style: GoogleFonts.jetBrainsMono(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    duration: const Duration(seconds: 2),
                    backgroundColor: AutomotiveColors.electricCyan,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AutomotiveColors.glassPanel,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AutomotiveColors.electricCyan, width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: AutomotiveColors.electricCyan.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: AutomotiveColors.electricCyan,
                  size: 24,
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
    final Color activeColor = badgeColor ?? AutomotiveColors.electricCyan;

    return InkWell(
      onTap: () => widget.onDestinationSelected(index),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 76,
        height: 64,
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : AutomotiveColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: isSelected
                  ? GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AutomotiveColors.textPrimary,
                    )
                  : GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.normal,
                      color: AutomotiveColors.textSecondary,
                    ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
