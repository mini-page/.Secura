import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _storage = StorageService();
    _loadTheme();
    return ThemeMode.light;
  }

  late final StorageService _storage;

  Future<void> _loadTheme() async {
    state = await _storage.getThemeMode();
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    _storage.saveThemeMode(mode);
  }
}
