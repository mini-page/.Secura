import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF5B5EF7);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      background: const Color(0xFFF4F6FA),
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFFF4F6FA),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827)),
      titleLarge: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827)),
      bodyLarge: TextStyle(color: Color(0xFF4B5563)),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF7C83FF),
      brightness: Brightness.dark,
      background: const Color(0xFF0E1117),
      surface: const Color(0xFF171C24),
    ),
    scaffoldBackgroundColor: const Color(0xFF0E1117),
    cardTheme: CardThemeData(
      color: const Color(0xFF171C24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
    ),
  );
}
