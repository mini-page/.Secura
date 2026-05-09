import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/google_auth_service.dart';
import '../../core/services/backup_service.dart';
import '../../components/secura_notifications.dart';

class GoogleSyncScreen extends ConsumerStatefulWidget {
  const GoogleSyncScreen({super.key});

  @override
  ConsumerState<GoogleSyncScreen> createState() => _GoogleSyncScreenState();
}

class _GoogleSyncScreenState extends ConsumerState<GoogleSyncScreen> {
  bool _isBackingUp = false;
  bool _isRestoring = false;

  Future<void> _handleBackup() async {
    final account = GoogleAuthService.currentUser;
    if (account == null) {
      _showSignInRequired();
      return;
    }

    setState(() => _isBackingUp = true);
    try {
      await BackupService.performBackup(account);
      if (mounted) {
        SecuraNotifications.showSuccess(context, 'Backup successful!');
      }
    } catch (e) {
      if (mounted) {
        SecuraNotifications.showError(context, 'Backup failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _handleRestore() async {
    final account = GoogleAuthService.currentUser;
    if (account == null) {
      _showSignInRequired();
      return;
    }

    setState(() => _isRestoring = true);
    try {
      final hasBackup = await BackupService.checkBackupExists(account);
      if (hasBackup == null) {
        if (mounted) {
          SecuraNotifications.showError(context, 'No backup found to restore');
        }
        return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restore Backup?'),
          content: const Text('This will restore your settings and profile. Vault files will NOT be affected.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore')),
          ],
        ),
      );

      if (confirm == true) {
        await BackupService.performRestore(account);
        if (mounted) {
          SecuraNotifications.showSuccess(context, 'Restore successful!');
        }
      }
    } catch (e) {
      if (mounted) {
        SecuraNotifications.showError(context, 'Restore failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  void _showSignInRequired() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign In Required'),
        content: const Text('You need to sign in with Google to use cloud sync features.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _handleSignIn();
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignIn() async {
    try {
      final account = await GoogleAuthService.signIn();
      if (account != null && mounted) {
        SecuraNotifications.showSuccess(context, 'Signed in as ${account.email}');
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        SecuraNotifications.showError(context, 'Sign in failed: $e');
      }
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('You will need to sign in again to use cloud features.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await GoogleAuthService.signOut();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = GoogleAuthService.currentUser;
    final isSignedIn = user != null;
    final photoUrl = isSignedIn ? user.photoUrl : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sync'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: isSignedIn
                        ? null
                        : const Icon(Icons.person_rounded, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSignedIn ? (user.displayName ?? 'Google User') : 'Not Signed In',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        if (isSignedIn)
                          Text(
                            user.email ?? '',
                            style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                          )
                        else
                          Text(
                            'Sign in to enable cloud backup',
                            style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sync Options
          Text('CLOUD OPERATIONS', style: Theme.of(context).textTheme.titleSmall?.copyWith(
            letterSpacing: 1.5, color: Theme.of(context).hintColor, fontSize: 11, fontWeight: FontWeight.w900,
          )),
          const SizedBox(height: 12),

          // Backup Option
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.cloud_upload_rounded, color: Theme.of(context).primaryColor, size: 22),
              ),
              title: const Text('Backup to Drive', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Save settings & profile securely'),
              trailing: _isBackingUp
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.chevron_right_rounded, size: 20, color: Theme.of(context).hintColor),
              onTap: _isBackingUp ? null : _handleBackup,
            ),
          ),
          const SizedBox(height: 12),

          // Restore Option
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.cloud_download_rounded, color: Theme.of(context).colorScheme.tertiary, size: 22),
              ),
              title: const Text('Restore from Drive', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Restore your backup data'),
              trailing: _isRestoring
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.chevron_right_rounded, size: 20, color: Theme.of(context).hintColor),
              onTap: _isRestoring ? null : _handleRestore,
            ),
          ),

          const SizedBox(height: 24),

          // Account Actions
          Text('ACCOUNT', style: Theme.of(context).textTheme.titleSmall?.copyWith(
            letterSpacing: 1.5, color: Theme.of(context).hintColor, fontSize: 11, fontWeight: FontWeight.w900,
          )),
          const SizedBox(height: 12),

          Card(
            child: isSignedIn
                ? ListTile(
                    leading: Icon(Icons.logout_rounded, color: Colors.orange.shade700),
                    title: const Text('Sign Out', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w700)),
                    onTap: _handleSignOut,
                  )
                : ListTile(
                    leading: Icon(Icons.login_rounded, color: Theme.of(context).primaryColor),
                    title: const Text('Sign In with Google', style: TextStyle(fontWeight: FontWeight.w700)),
                    trailing: Icon(Icons.chevron_right_rounded, size: 20, color: Theme.of(context).hintColor),
                    onTap: _handleSignIn,
                  ),
          ),

          const SizedBox(height: 40),
          Center(
            child: Text(
              'Your data is encrypted before upload',
              style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}