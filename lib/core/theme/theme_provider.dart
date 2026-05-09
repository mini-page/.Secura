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

  void setThemeMode(ThemeMode mode) {
    final theme = mode == ThemeMode.dark
        ? SecuraTheme.presets[1]
        : SecuraTheme.presets[0];
    setTheme(theme);
  }
}