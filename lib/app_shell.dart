import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:animations/animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/vault/import_screen.dart';

import 'features/settings/settings_screen.dart';
import 'features/settings/settings_provider.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/user_provider.dart';
import 'features/vault/decrypt_screen.dart';
import 'features/vault/encrypt_screen.dart';
import 'features/vault/home_screen.dart';

class VaultShell extends ConsumerStatefulWidget {
  const VaultShell({super.key});

  @override
  ConsumerState<VaultShell> createState() => _VaultShellState();
}

class _VaultShellState extends ConsumerState<VaultShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isBottomNavVisible = true;
  DateTime? _pausedTime;
  DateTime? _lastBackPress;

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPress != null && now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
      return true;
    }
    _lastBackPress = now;
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tap again to exit'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    return false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pausedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedTime == null) return;
      final strict2FA = ref.read(strict2FAProvider);
      final autoLock = ref.read(autoLockProvider);
      final diff = DateTime.now().difference(_pausedTime!);

      bool shouldLock = false;
      if (strict2FA) {
        shouldLock = true;
      } else if (autoLock && diff.inMinutes >= 5) {
        shouldLock = true;
      }

      if (shouldLock) {
        ref.read(sessionProvider.notifier).clearSession();
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen(isSetup: false)),
          (route) => false,
        );
      }
      _pausedTime = null;
    }
  }

  Future<void> _pickAndAddFile() async {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ImportScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const EncryptScreen(),
      const DecryptScreen(),
      const SettingsScreen(),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
        children: [
          // Main Content
          NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.direction == ScrollDirection.reverse) {
                if (_isBottomNavVisible) setState(() => _isBottomNavVisible = false);
              } else if (notification.direction == ScrollDirection.forward) {
                if (!_isBottomNavVisible) setState(() => _isBottomNavVisible = true);
              }
              return true;
            },
            child: PageTransitionSwitcher(
              duration: const Duration(milliseconds: 500),
              reverse: false,
              transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
                return SharedAxisTransition(
                  animation: primaryAnimation,
                  secondaryAnimation: secondaryAnimation,
                  transitionType: SharedAxisTransitionType.horizontal,
                  child: child,
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_currentIndex),
                child: screens[_currentIndex],
              ),
            ),
          ),
          
          // Floating Navigation Bar (Dynamic Island)
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutQuart,
                  offset: _isBottomNavVisible ? Offset.zero : const Offset(0, 1.5),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _isBottomNavVisible ? 1.0 : 0.0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutQuint,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      height: 72,
                      width: MediaQuery.of(context).size.width * 0.90,
                      decoration: BoxDecoration(
                        color: isDark 
                            ? const Color(0xFF1E242E).withValues(alpha: 0.98) 
                            : Colors.white.withValues(alpha: 0.98),
                        borderRadius: BorderRadius.circular(36),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 40,
                            offset: const Offset(0, 15),
                          ),
                        ],
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.05),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildNavItem(Icons.home_outlined, Icons.home_rounded, 0, accentColor),
                          _buildNavItem(Icons.lock_open_rounded, Icons.lock_rounded, 1, accentColor),
                          
                          // Always Visible Plus Button (Subtle accent styling)
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _pickAndAddFile,
                              child: Center(
                                child: Icon(
                                  Icons.add_circle_outline_rounded,
                                  color: accentColor,
                                  size: 38,
                                ),
                              ),
                            ),
                          ),

                          _buildNavItem(Icons.key_outlined, Icons.key_rounded, 2, accentColor),
                          _buildNavItem(Icons.settings_outlined, Icons.settings_rounded, 3, accentColor),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData selectedIcon, int index, Color accentColor) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isSelected
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? Colors.white70 : Colors.grey);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentIndex = index),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? accentColor : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 400),
              scale: isSelected ? 1.1 : 1.0,
              curve: Curves.easeOutBack,
              child: Icon(
                isSelected ? selectedIcon : icon,
                size: 26,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
