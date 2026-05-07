import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  final _storage = StorageService();

  Future<void> _loadTheme() async {
    state = await _storage.getThemeMode();
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    _storage.saveThemeMode(mode);
  }
}
