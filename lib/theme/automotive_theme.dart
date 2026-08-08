import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'automotive_colors.dart';

class AutomotiveTheme {
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AutomotiveColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AutomotiveColors.electricCyan,
        secondary: AutomotiveColors.dongleViolet,
        surface: AutomotiveColors.glassPanel,
        error: AutomotiveColors.redAccent,
      ),
      cardTheme: CardThemeData(
        color: AutomotiveColors.glassPanel,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AutomotiveColors.stroke, width: 1),
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        // Display Headings - Space Grotesk (700 Bold)
        headlineLarge: GoogleFonts.spaceGrotesk(
          fontSize: 38,
          fontWeight: FontWeight.bold,
          color: AutomotiveColors.textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: AutomotiveColors.textPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AutomotiveColors.textPrimary,
        ),
        // Subheads & Control Labels - Inter
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AutomotiveColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: AutomotiveColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: AutomotiveColors.textSecondary,
        ),
        // Data & Monospace Labels - JetBrains Mono
        labelLarge: GoogleFonts.jetBrainsMono(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AutomotiveColors.electricCyan,
        ),
        labelMedium: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          fontWeight: FontWeight.normal,
          color: AutomotiveColors.textMuted,
        ),
      ),
      iconTheme: const IconThemeData(
        color: AutomotiveColors.electricCyan,
        size: 24,
      ),
    );
  }
}
