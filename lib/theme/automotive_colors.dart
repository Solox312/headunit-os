import 'package:flutter/material.dart';

/// HeadUnit OS Brand Identity Color Tokens
/// Derived from HeadUnitOS_Brand_Identity.html
class AutomotiveColors {
  // Base Backgrounds
  static const Color background = Color(0xFF0B0E14);      // Dash Black - Base surface
  static const Color panel = Color(0xFF151B26);           // Base panel
  static const Color glassPanel = Color(0xFF1B2230);      // Glass panel / elevated tiles (panel2)
  static const Color panelDark = Color(0xFF0F1420);       // Dark panel / mono background (panel3)
  static const Color cardBackground = Color(0xFF1B2230);  // Card / Tile background

  // Borders & Strokes
  static const Color stroke = Color(0xFF262E3D);          // 1px hairline stroke
  static const Color strokeSoft = Color(0xFF1D2432);      // Subtle divider
  static const Color cardBorder = Color(0xFF262E3D);      // Card border stroke

  // Accent Colors & Signals
  static const Color electricCyan = Color(0xFF00E5D4);    // Electric Cyan - Primary accent / native path
  static const Color cyanAccent = Color(0xFF00E5D4);      // Primary accent alias
  static const Color dongleViolet = Color(0xFFB18CFF);    // Dongle Violet - Hardware bridge signal
  static const Color violetAccent = Color(0xFFB18CFF);    // Dongle Violet alias
  static const Color nativeGreen = Color(0xFF3DDC84);     // Native Green - Status OK / $0 confirmation
  static const Color greenAccent = Color(0xFF3DDC84);     // Status green alias
  static const Color orangeAccent = Color(0xFFFF9100);    // Warnings / highlights
  static const Color redAccent = Color(0xFFFF6A7A);       // Alerts / error state

  // Text & Typography
  static const Color textPrimary = Color(0xFFE9EDF5);     // Text main (#E9EDF5)
  static const Color textSecondary = Color(0xFF8A93A6);   // Muted labels (#8A93A6)
  static const Color textMuted = Color(0xFF5C6579);       // Muted2 data details (#5C6579)

  // Projection Brand Identifiers
  static const Color carPlayColor = Color(0xFF007AFF);    // Apple CarPlay Signature Blue
  static const Color androidAutoColor = Color(0xFF34A853); // Android Auto Signature Green
}
