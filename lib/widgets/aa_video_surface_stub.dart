import 'package:flutter/material.dart';

/// Stub implementation used on non-Linux platforms (Windows, macOS).
/// Returns an empty SizedBox — the Windows simulation branch in
/// aa_video_surface.dart handles the actual UI on non-Linux.
Widget buildLinuxVideoSurface({required String deviceName}) {
  return const SizedBox.expand();
}
