import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF575992);

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        surface: isDark ? const Color(0xFF0E1117) : const Color(0xFFF4F6FA),
      ),
      scaffoldBackgroundColor: isDark ? const Color(0xFF0E1117) : const Color(0xFFF4F6FA),
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.bricolageGrotesqueTextTheme(baseTheme.textTheme).copyWith(
        headlineLarge: GoogleFonts.bricolageGrotesque(
          fontWeight: FontWeight.w900,
          fontSize: 36,
          letterSpacing: -1.5,
          color: isDark ? Colors.white : const Color(0xFF111827),
        ),
        headlineMedium: GoogleFonts.bricolageGrotesque(
          fontWeight: FontWeight.w800,
          fontSize: 28,
          letterSpacing: -1,
          color: isDark ? Colors.white : const Color(0xFF111827),
        ),
        titleLarge: GoogleFonts.bricolageGrotesque(
          fontWeight: FontWeight.w800,
          fontSize: 22,
          color: isDark ? Colors.white : const Color(0xFF111827),
        ),
        titleMedium: GoogleFonts.bricolageGrotesque(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: isDark ? Colors.white : const Color(0xFF111827),
        ),
        bodyLarge: GoogleFonts.bricolageGrotesque(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
        ),
        labelLarge: GoogleFonts.bricolageGrotesque(
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF171C24) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        elevation: 0,
      ),
    );
  }
}
