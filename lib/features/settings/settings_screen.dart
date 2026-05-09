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
import 'google_sync_screen.dart';
import 'team_screen.dart';
import '../../core/services/storage_service.dart';
import '../splash/splash_screen.dart';
import '../../core/theme/theme_provider.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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
          const AppHeader(title: 'Settings', showSearch: false),
          const SizedBox(height: 16),

          // Profile & Cloud Sync Card merged
          ShimmerCard(
            child: Card(
              child: Column(
                children: [
                  // Profile Section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
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
                                  const SizedBox(height: 2),
                                  Text(
                                    user?.email ?? 'No Identity Attached',
                                    style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileEditScreen())),
                              icon: Icon(Icons.edit_outlined, size: 16, color: Theme.of(context).hintColor),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Quick Cloud Actions - merged into profile card
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: _QuickActionTile(
                            icon: Icons.cloud_upload_rounded,
                            label: 'Backup',
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GoogleSyncScreen())),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _QuickActionTile(
                            icon: Icons.cloud_download_rounded,
                            label: 'Restore',
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GoogleSyncScreen())),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _QuickActionTile(
                            icon: Icons.sync_rounded,
                            label: 'Sync',
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GoogleSyncScreen())),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stats section
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
          Text('APPEARANCE & THEME', style: Theme.of(context).textTheme.titleSmall?.copyWith(letterSpacing: 1.5, color: Theme.of(context).hintColor, fontSize: 11, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          ModernThemeSelector(
            selectedTheme: selectedTheme,
            onModeChanged: (mode) => ref.read(themeProvider.notifier).setThemeMode(mode),
            onColorChanged: (colorBaseId) => ref.read(themeProvider.notifier).setAccentColor(colorBaseId),
          ),

          const SizedBox(height: 24),
          Text('SECURITY', style: Theme.of(context).textTheme.titleSmall?.copyWith(letterSpacing: 1.5, color: Theme.of(context).hintColor, fontSize: 11, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                AppToggleTile(
                  title: 'Strict 2FA Mode',
                  subtitle: 'Require identity check on every launch',
                  value: strict2FA,
                  onChanged: (v) => ref.read(strict2FAProvider.notifier).toggle(v),
                ),
                const Divider(height: 1, indent: 56),
                AppToggleTile(
                  title: 'Auto-Lock Timeout',
                  subtitle: 'Lock vault after 5 mins of inactivity',
                  value: autoLock,
                  onChanged: (v) => ref.read(autoLockProvider.notifier).toggle(v),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.fingerprint_rounded),
                  title: Row(
                    children: [
                      const Text('Biometric Unlock', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Coming Soon', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  subtitle: const Text('Use fingerprint or face to unlock'),
                  enabled: false,
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.enhanced_encryption_rounded),
                  title: Row(
                    children: [
                      const Text('Advanced Encryption', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Coming Soon', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  subtitle: const Text('Maximum security encryption'),
                  enabled: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('MANAGE', style: Theme.of(context).textTheme.titleSmall?.copyWith(letterSpacing: 1.5, color: Theme.of(context).hintColor, fontSize: 11, fontWeight: FontWeight.w900)),
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
                  leading: const Icon(Icons.people_outline_rounded),
                  title: const Text('The Team', style: TextStyle(fontWeight: FontWeight.w700)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TeamScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('ACCOUNT', style: Theme.of(context).textTheme.titleSmall?.copyWith(letterSpacing: 1.5, color: Theme.of(context).hintColor, fontSize: 11, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
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

  Widget _QuickActionTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).primaryColor),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onPrimaryContainer)),
          ],
        ),
      ),
    );
  }

  void _showAdvancedEncryptionInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.enhanced_encryption_rounded, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('Advanced Encryption', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔒 What it does:',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4),
            Text('• PBKDF2 with 600,000 iterations'),
            Text('• AES-256-GCM encryption'),
            Text('• Maximum security for your files'),
            SizedBox(height: 12),
            Text(
              '⚡ Current Mode:',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4),
            Text('• Fast AES-256 encryption'),
            Text('• Quick app unlock'),
            Text('• Optimized for daily use'),
            SizedBox(height: 12),
            Text(
              '📅 Coming Soon:',
              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.orange),
            ),
            SizedBox(height: 4),
            Text('Toggle between modes when launched on Play Store. Replace with new feature at release.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
