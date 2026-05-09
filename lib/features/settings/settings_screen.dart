import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/components.dart';
import '../../components/shimmer_card.dart';
import '../vault/vault_provider.dart';
import '../auth/auth_screen.dart';
import '../auth/user_provider.dart';
import '../auth/profile_edit_screen.dart';
import 'about_screen.dart';
import 'recycle_bin_screen.dart';
import 'activity_logs_screen.dart';
import '../../core/services/storage_service.dart';
import '../splash/splash_screen.dart';
import '../../core/theme/theme_provider.dart';
import 'settings_provider.dart';

import '../../core/services/google_auth_service.dart';
import '../../core/services/backup_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isBackingUp = false;

  Future<void> _handleManualBackup() async {
    final account = GoogleAuthService.currentUser;
    if (account == null) {
      SecuraNotifications.showError(context, 'Please sign in to Google first.');
      return;
    }

    setState(() => _isBackingUp = true);
    try {
      await BackupService.performBackup(account);
      if (mounted) {
        SecuraNotifications.showSuccess(context, 'Cloud backup successful!');
      }
    } catch (e) {
      if (mounted) {
        SecuraNotifications.showError(context, 'Backup failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(vaultProvider);
    final user = ref.watch(userProvider);
    final selectedTheme = ref.watch(themeProvider);
    final strict2FA = ref.watch(strict2FAProvider);
    final autoLock = ref.watch(autoLockProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          const AppHeader(title: 'Settings'),
          const SizedBox(height: 16),

          ShimmerCard(
            child: Card(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          child: Text(user?.profileEmoji ?? '👤', style: const TextStyle(fontSize: 24)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user?.name ?? 'Secura User', style: Theme.of(context).textTheme.titleLarge),
                              Text(user?.email ?? 'No Identity Attached', style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileEditScreen())),
                          icon: const Icon(Icons.edit_outlined, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  vaultState.when(
                    data: (files) {
                      final encryptedCount = files.where((f) => f.isEncrypted).length;
                      final totalSize = files.fold<int>(0, (sum, f) => sum + f.size);
                      final sizeMb = (totalSize / (1024 * 1024)).toStringAsFixed(1);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMiniStat(files.length.toString(), 'FILES'),
                            _buildMiniStat(encryptedCount.toString(), 'SECURE'),
                            _buildMiniStat('$sizeMb MB', 'USED'),
                          ],
                        ),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          Text('APPEARANCE', style: Theme.of(context).textTheme.titleSmall?.copyWith(letterSpacing: 1.5, color: Theme.of(context).hintColor, fontSize: 11, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          ThemePresetSelector(
            selected: selectedTheme,
            onChanged: (newTheme) {
              ref.read(themeProvider.notifier).setTheme(newTheme);
            },
          ),

          const SizedBox(height: 24),
          Text('CLOUD SYNC', style: Theme.of(context).textTheme.titleSmall?.copyWith(letterSpacing: 1.5, color: Theme.of(context).hintColor, fontSize: 11, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(_isBackingUp ? Icons.sync_rounded : Icons.cloud_upload_rounded, color: Theme.of(context).primaryColor),
              title: const Text('Backup to Google Drive', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('Save your settings and profile safely', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).hintColor)),
              trailing: _isBackingUp 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: _isBackingUp ? null : _handleManualBackup,
            ),
          ),

          const SizedBox(height: 24),
          Text('SECURITY', style: Theme.of(context).textTheme.titleSmall?.copyWith(letterSpacing: 1.5, color: Theme.of(context).hintColor, fontSize: 11, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          AppToggleTile(
            title: 'Strict 2FA Mode',
            subtitle: 'Require identity check on every launch',
            value: strict2FA,
            onChanged: (v) => ref.read(strict2FAProvider.notifier).toggle(v),
          ),
          const SizedBox(height: 8),
          AppToggleTile(
            title: 'Auto-Lock Timeout',
            subtitle: 'Lock vault after 5 mins of inactivity',
            value: autoLock,
            onChanged: (v) => ref.read(autoLockProvider.notifier).toggle(v),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_reset_rounded),
                  title: const Text('Change Access PIN', style: TextStyle(fontWeight: FontWeight.w700)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthScreen(isSetup: true))),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.restore_from_trash_rounded),
                  title: const Text('Recycle Bin', style: TextStyle(fontWeight: FontWeight.w700)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RecycleBinScreen())),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.history_rounded),
                  title: const Text('Activity Logs', style: TextStyle(fontWeight: FontWeight.w700)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ActivityLogsScreen())),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('About Secura', style: TextStyle(fontWeight: FontWeight.w700)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen())),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.orange),
                  title: const Text('Sign Out', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w700)),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Sign Out?', style: TextStyle(fontWeight: FontWeight.w900)),
                        content: const Text('Your vault will be locked. You can sign back in to access your files.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(userProvider.notifier).logout();
                      if (!context.mounted) return;
                      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const SplashScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                  title: const Text('Factory Reset App', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Nuclear Reset?', style: TextStyle(fontWeight: FontWeight.w900)),
                        content: const Text('This will wipe ALL files and settings. This cannot be undone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            child: const Text('Reset Everything'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await StorageService().clearAll();
                      if (!context.mounted) return;
                      // Navigate back to splash
                      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const SplashScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
          Center(
            child: Text(
              'SECURA PRIVACY PROTOCOL v1.0',
              style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Theme.of(context).hintColor, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        Text(label, style: TextStyle(fontSize: 9, color: Theme.of(context).hintColor, letterSpacing: 1, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
