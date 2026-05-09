import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SecuraTheme {
  final String id;
  final String name;
  final Color primaryColor;
  final bool isDark;

  const SecuraTheme({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.isDark,
  });

  static const List<SecuraTheme> presets = [
    SecuraTheme(id: 'default_light', name: 'Ocean Blue', primaryColor: Color(0xFF575992), isDark: false),
    SecuraTheme(id: 'default_dark', name: 'Midnight', primaryColor: Color(0xFF575992), isDark: true),
    SecuraTheme(id: 'emerald_light', name: 'Emerald', primaryColor: Color(0xFF059669), isDark: false),
    SecuraTheme(id: 'emerald_dark', name: 'Emerald Night', primaryColor: Color(0xFF10B981), isDark: true),
    SecuraTheme(id: 'rose_light', name: 'Rose', primaryColor: Color(0xFFE11D48), isDark: false),
    SecuraTheme(id: 'rose_dark', name: 'Rose Night', primaryColor: Color(0xFFF43F5E), isDark: true),
    SecuraTheme(id: 'violet_light', name: 'Violet', primaryColor: Color(0xFF7C3AED), isDark: false),
    SecuraTheme(id: 'violet_dark', name: 'Violet Night', primaryColor: Color(0xFF8B5CF6), isDark: true),
    SecuraTheme(id: 'amber_light', name: 'Amber', primaryColor: Color(0xFFD97706), isDark: false),
    SecuraTheme(id: 'amber_dark', name: 'Amber Night', primaryColor: Color(0xFFF59E0B), isDark: true),
    SecuraTheme(id: 'teal_light', name: 'Teal', primaryColor: Color(0xFF0D9488), isDark: false),
    SecuraTheme(id: 'teal_dark', name: 'Teal Night', primaryColor: Color(0xFF14B8A6), isDark: true),
  ];

  static SecuraTheme? fromId(String id) {
    try {
      return presets.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  static SecuraTheme fromThemeMode(ThemeMode mode) {
    return mode == ThemeMode.dark ? presets[1] : presets[0];
  }

  ThemeData get themeData => _buildTheme();

  ThemeData _buildTheme() {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
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