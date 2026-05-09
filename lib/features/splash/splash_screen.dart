import 'package:flutter/material.dart';
import '../../core/services/storage_service.dart';
import '../onboarding/onboarding_screen.dart';
import '../auth/auth_screen.dart';

import '../../core/services/google_auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    // Refresh Google Session
    await GoogleAuthService.signInSilently();

    final authHash = await _storage.getAuthHash();
    final user = await _storage.getCurrentUser();

    if (!mounted) return;

    if (authHash != null && user != null) {
      _goToAuth();
    } else {
      _goToOnboarding();
    }
  }

  void _goToOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const OnboardingScreen(),
      ),
    );
  }

  void _goToAuth() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AuthScreen(
          isSetup: false,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/app_brand.png', width: 180, height: 180),
            const SizedBox(height: 24),
            Text(
              'SECURA',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF575992),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
