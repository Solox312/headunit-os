import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/wireless_aa_bridge.dart';
import '../theme/automotive_colors.dart';

import 'aa_video_surface_linux.dart'
    if (dart.library.html) 'aa_video_surface_stub.dart'
    as platform;

/// Full-screen H.264 video surface for Android Auto streaming.
///
/// On Linux/RPi: connects to OpenAuto's UDP video stream (udp://127.0.0.1:5556)
///               via media_kit + libmpv. Touch events are forwarded back to
///               the phone via WirelessAABridge.
///
/// On Windows:   renders a simulation overlay showing device info.
class AAVideoSurface extends StatelessWidget {
  final String deviceName;
  final int phoneBattery;
  final VoidCallback? onDisconnect;

  const AAVideoSurface({
    super.key,
    required this.deviceName,
    required this.phoneBattery,
    this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Platform.isLinux
            ? platform.buildLinuxVideoSurface(deviceName: deviceName)
            : _buildWindowsSimulation(),
        Positioned(
          top: 10,
          right: 10,
          child: _buildStatusBar(),
        ),
      ],
    );
  }

  Widget _buildWindowsSimulation() {
    return GestureDetector(
      onPanDown: (d) => WirelessAABridge().sendTouchEvent(d.localPosition.dx, d.localPosition.dy, 0),
      onPanUpdate: (d) => WirelessAABridge().sendTouchEvent(d.localPosition.dx, d.localPosition.dy, 1),
      onPanEnd: (_) => WirelessAABridge().sendTouchEvent(0, 0, 2),
      child: Container(
        color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AutomotiveColors.androidAutoColor.withValues(alpha: 0.12),
                border: Border.all(
                  color: AutomotiveColors.androidAutoColor.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: const Icon(Icons.android_rounded, size: 56, color: AutomotiveColors.androidAutoColor),
            ),
            const SizedBox(height: 20),
            Text(
              'Android Auto',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'H.264 video stream active on Linux/RPi deployment',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white38),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: AutomotiveColors.androidAutoColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AutomotiveColors.androidAutoColor.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone_android_rounded, size: 15, color: AutomotiveColors.androidAutoColor),
                  const SizedBox(width: 8),
                  Text(
                    deviceName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AutomotiveColors.androidAutoColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.battery_charging_full_rounded, size: 15, color: Colors.greenAccent),
                  const SizedBox(width: 4),
                  Text(
                    '$phoneBattery%',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.greenAccent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return GestureDetector(
      onTap: onDisconnect,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.android_rounded, size: 13, color: AutomotiveColors.androidAutoColor),
            const SizedBox(width: 6),
            Text(
              deviceName,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.battery_full_rounded, size: 12, color: Colors.greenAccent),
            Text(
              '$phoneBattery%',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.greenAccent),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.close_rounded, size: 14, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
