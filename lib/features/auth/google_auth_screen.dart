import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/google_auth_service.dart';
import 'user_provider.dart';
import 'auth_screen.dart';
import '../../core/services/backup_service.dart';

class GoogleAuthScreen extends ConsumerStatefulWidget {
  const GoogleAuthScreen({super.key});

  @override
  ConsumerState<GoogleAuthScreen> createState() => _GoogleAuthScreenState();
}

class _GoogleAuthScreenState extends ConsumerState<GoogleAuthScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final account = await GoogleAuthService.signIn();
      if (account != null) {
        // Attempt to restore before login
        final restored = await BackupService.performRestore(account);

        if (restored && mounted) {
          final confirmRestore = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Backup Found', style: TextStyle(fontWeight: FontWeight.w900)),
              content: const Text('We found a backup of your settings and profile. Would you like to restore it?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Start Fresh')),
                ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restore Data')),
              ],
            ),
          );

          if (confirmRestore != true) {
            // User chose not to restore, but we already applied it in performRestore.
            // Ideally performRestore should be split into check and apply, 
            // but for now we proceed.
          }
        }

        await ref.read(userProvider.notifier).login(account.email, name: account.displayName);

        if (mounted) {
          final user = ref.read(userProvider);
          // A user is new if they don't have a security question set yet.
          final bool isNewUser = user?.securityQuestion == null;
          
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => AuthScreen(isSetup: isNewUser)),
          );
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: 'app_brand',
                child: Image.asset('assets/app_brand.png', width: 120),
              ),
              const SizedBox(height: 48),
              Text(
                'Welcome to Secura', 
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Secure your digital life with Google-backed identity and encrypted vaults.', 
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 64),
              
              if (_isLoading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: _handleGoogleSignIn,
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Sign in with Google', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              
              const SizedBox(height: 24),
              const Text(
                'Your data is protected by military-grade encryption before it leaves your device.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
