import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'automotive_colors.dart';

class AutomotiveTheme {
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AutomotiveColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AutomotiveColors.cyanAccent,
        secondary: AutomotiveColors.blueAccent,
        surface: AutomotiveColors.cardBackground,
        error: AutomotiveColors.redAccent,
      ),
      cardTheme: CardThemeData(
        color: AutomotiveColors.cardBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AutomotiveColors.cardBorder, width: 1),
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: GoogleFonts.orbitron(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: AutomotiveColors.textPrimary,
          letterSpacing: 1.2,
        ),
        headlineMedium: GoogleFonts.orbitron(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AutomotiveColors.textPrimary,
          letterSpacing: 1.0,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AutomotiveColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AutomotiveColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AutomotiveColors.textSecondary,
        ),
      ),
      iconTheme: const IconThemeData(
        color: AutomotiveColors.textPrimary,
        size: 26,
      ),
    );
  }
}
