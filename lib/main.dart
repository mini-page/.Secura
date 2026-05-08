import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secure_application/secure_application.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/splash/splash_screen.dart';
import 'core/services/google_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await GoogleAuthService.init().timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('Google Auth Initialization Error: $e');
  }
  
  runApp(
    const ProviderScope(
      child: SecuraApp(),
    ),
  );
}

class SecuraApp extends ConsumerWidget {
  const SecuraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Secura',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      builder: (context, child) {
        return SecureApplication(
          onNeedUnlock: (secure) => null,
          child: SecureGate(
            blurr: 20,
            opacity: 0.6,
            lockedBuilder: (context, secureNotifier) => Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/app_brand.png',
                      width: 150,
                      height: 150,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Secura is Locked',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
            ),
            child: child!,
          ),
        );
      },
      home: const SplashScreen(),
    );
  }
}

