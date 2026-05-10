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
    // Exact Splash Duration: 400ms
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    // 1. Refresh Google Session
    await GoogleAuthService.signInSilently();
    final user = await _storage.getCurrentUser();

    // 2. Check Permissions (Handled in Onboarding or Auth, but Splash routes if missing)
    
    // 3. Check Security Status
    final authHash = await _storage.getAuthHash();

    if (!mounted) return;

    // STRICT SEQUENTIAL FLOW
    if (user == null) {
      // Step 1 & 2: Onboarding & Google Login
      _goToOnboarding();
    } else if (authHash == null) {
      // Step 3: PIN Setup
      _goToPinSetup();
    } else if (user.securityQuestion == null) {
      // Step 4: Recovery Setup
      _goToRecoverySetup();
    } else {
      // Final: Enter App
      _goToAuth();
    }
  }

  void _goToOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
    );
  }

  void _goToPinSetup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthScreen(isSetup: true)),
    );
  }

  void _goToRecoverySetup() {
    // Route to AuthScreen in setup mode, but it will internally detect it needs recovery
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthScreen(isSetup: true)),
    );
  }

  void _goToAuth() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AuthScreen(isSetup: false),
        transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
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
