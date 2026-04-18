import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/auth_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/vault/decrypt_screen.dart';
import 'features/vault/encrypt_screen.dart';
import 'features/vault/home_screen.dart';

void main() {
  runApp(const SecuraApp());
}

class SecuraApp extends StatefulWidget {
  const SecuraApp({super.key});

  @override
  State<SecuraApp> createState() => _SecuraAppState();
}

class _SecuraAppState extends State<SecuraApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _onThemeChanged(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secura',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: OnboardingScreen(
        onGetStarted: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AuthScreen(
                onAuthenticated: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => VaultShell(
                        onThemeChanged: _onThemeChanged,
                        initialTheme: _themeMode,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class VaultShell extends StatefulWidget {
  const VaultShell({
    required this.onThemeChanged,
    required this.initialTheme,
    super.key,
  });

  final ValueChanged<ThemeMode> onThemeChanged;
  final ThemeMode initialTheme;

  @override
  State<VaultShell> createState() => _VaultShellState();
}

class _VaultShellState extends State<VaultShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const EncryptScreen(),
      const DecryptScreen(),
      SettingsScreen(
        initialTheme: widget.initialTheme,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.lock_outline), label: 'Encrypt'),
          NavigationDestination(icon: Icon(Icons.key_outlined), label: 'Decrypt'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}
