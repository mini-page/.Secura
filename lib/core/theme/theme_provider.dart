import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import 'custom_theme.dart';

final themeProvider = NotifierProvider<ThemeNotifier, SecuraTheme>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<SecuraTheme> {
  @override
  SecuraTheme build() {
    _storage = StorageService();
    _loadTheme();
    return SecuraTheme.presets[0];
  }

  late final StorageService _storage;

  Future<void> _loadTheme() async {
    final themeId = await _storage.getThemeId();
    final theme = themeId != null
        ? SecuraTheme.fromId(themeId)
        : SecuraTheme.presets[0];
    state = theme ?? SecuraTheme.presets[0];
  }

  void setTheme(SecuraTheme theme) {
    state = theme;
    _storage.saveThemeId(theme.id);
  }

  void toggleMode() {
    final nextIsDark = !state.isDark;
    final baseId = state.id.split('_')[0];
    final newId = '${baseId}_${nextIsDark ? 'dark' : 'light'}';
    final newTheme = SecuraTheme.fromId(newId);
    if (newTheme != null) {
      setTheme(newTheme);
    }
  }

  void setAccentColor(String colorBaseId) {
    final newId = '${colorBaseId}_${state.isDark ? 'dark' : 'light'}';
    final newTheme = SecuraTheme.fromId(newId);
    if (newTheme != null) {
      setTheme(newTheme);
    }
  }

  void setThemeMode(ThemeMode mode) {
    final isDark = mode == ThemeMode.dark;
    if (state.isDark == isDark) return;
    
    final baseId = state.id.split('_')[0];
    final newId = '${baseId}_${isDark ? 'dark' : 'light'}';
    final newTheme = SecuraTheme.fromId(newId);
    if (newTheme != null) {
      setTheme(newTheme);
    }
  }
}