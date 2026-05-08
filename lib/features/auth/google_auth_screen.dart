import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/google_auth_service.dart';
import 'user_provider.dart';
import 'auth_screen.dart';
import '../../core/services/backup_service.dart';
import '../../components/secura_notifications.dart';

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
        // First check if backup exists WITHOUT restoring
        final backupMeta = await BackupService.checkBackupExists(account);

        // Show backup dialog AFTER login is complete but BEFORE entering vault
        if (backupMeta != null && mounted) {
          final confirmRestore = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cloud Backup Found', style: TextStyle(fontWeight: FontWeight.w900)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Last backup: ${_formatDate(backupMeta.timestamp)}'),
                  const SizedBox(height: 8),
                  const Text('Your settings and profile will be restored from this backup.'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your current vault files are NOT affected by this restore.',
                            style: TextStyle(fontSize: 11, color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Start Fresh'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Restore Backup'),
                ),
              ],
            ),
          );

          // Only restore NOW if user confirmed
          if (confirmRestore == true) {
            final restoreResult = await BackupService.performRestore(account);
            if (restoreResult.success) {
              if (mounted) {
                SecuraNotifications.showSuccess(context, 'Backup restored successfully!');
              }
            } else {
              if (mounted) {
                SecuraNotifications.showError(context, 'Restore failed: ${restoreResult.errorMessage}');
              }
            }
          }
        }

        // Complete login
        await ref.read(userProvider.notifier).login(account.email, name: account.displayName);

        if (mounted) {
          final user = ref.read(userProvider);
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
        SecuraNotifications.showError(context, 'Login Error: ${e.toString()}');
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
