import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secura/components/components.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Secura', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Project Identity
          Center(
            child: Column(
              children: [
                Image.asset('assets/app_brand.png', width: 140, height: 140),
                const SizedBox(height: 20),
                Text('SECURA VAULT', style: Theme.of(context).textTheme.headlineLarge),
                Text('V1.0.0', style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 40),

          _buildSectionHeader(context, 'THE MISSION'),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Secura is an elite, local-first file encryption vault. Using industry-standard AES-256-GCM encryption, we ensure your most sensitive data remains private, invisible, and under your total control.',
                style: TextStyle(height: 1.6, fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 32),

          _buildSectionHeader(context, 'CURRENT CAPABILITIES'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildFeatureItem(FontAwesomeIcons.google, 'Google-Backed Identity', 'Secure login using industry-standard Google OAuth protocols.', isFontAwesome: true),
                  _buildFeatureItem(Icons.enhanced_encryption_rounded, 'Fast Encryption', 'PBKDF2 key derivation - instant unlock with 10k iterations.'),
                  _buildFeatureItem(Icons.lock_rounded, 'Secure Storage', 'Hidden .locker_private folder - invisible to file managers.'),
                  _buildFeatureItem(Icons.cloud_done_rounded, 'Encrypted Settings Backup', 'Backup settings to Google Drive - encrypted before upload.'),
                  _buildFeatureItem(Icons.vpn_key_rounded, 'Zero-Knowledge Recovery', 'PIN recovery via security questions with local hashing.'),
                  _buildFeatureItem(Icons.auto_delete_rounded, 'Secure Shredding', 'Files overwritten and shredded after import to prevent recovery.'),
                  _buildFeatureItem(Icons.search_rounded, 'Robust Search', 'Search through your vault with real-time filtering.'),
                  _buildFeatureItem(Icons.filter_list_rounded, 'Filter Options', 'Filter files by All, Encrypted, or Decrypted status.'),
                  _buildFeatureItem(Icons.folder_zip_rounded, 'File Support', 'Images, Videos, Audio, Documents, PDF, Spreadsheets, Archives, Code.'),
                  _buildFeatureItem(Icons.data_usage_rounded, 'File Size Limit', 'Maximum 50MB per file for encryption operations.'),
                  _buildFeatureItem(Icons.timer_rounded, 'Auto-Lock', 'Vault auto-locks after 5 minutes of inactivity.'),
                  _buildFeatureItem(Icons.security_rounded, 'Strict 2FA Mode', 'Require identity check on every app launch.'),
                  _buildFeatureItem(Icons.history_rounded, 'Activity Logs', 'Track all vault operations with detailed timestamps.'),
                  _buildFeatureItem(Icons.delete_sweep_rounded, 'Recycle Bin', 'Soft-delete with permanent deletion option.'),
                  _buildFeatureItem(Icons.palette_rounded, 'Theme Customization', 'Light/Dark modes with multiple accent color options.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          _buildSectionHeader(context, 'SECURITY HANDSHAKE'),
          Card(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.1), width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.security_rounded, color: Colors.green, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'ZERO-KNOWLEDGE MODEL',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Secura is built on the principle that only you should own your keys. Your PIN and security answers are hashed locally using SHA-256 and never sent to any server. We cannot recover your files because we literally do not have the keys.',
                    style: TextStyle(height: 1.5, fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  _buildSecurityTerm('AES-256-GCM', 'Military-grade encryption used for every file in your locker.'),
                  _buildSecurityTerm('PBKDF2-HMAC-SHA256', 'Key derivation with configurable iterations (10k fast / 600k secure).'),
                  _buildSecurityTerm('IV Isolation', 'Every file uses a unique 12-byte initialization vector for maximum defense.'),
                  _buildSecurityTerm('Encrypted Metadata', 'Filenames are Base64 obfuscated to hide contents from OS search.'),
                  _buildSecurityTerm('Rate Limiting', '3 failed attempts → 30s lockout on PIN. Security questions: 5-min lockout.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Enhanced Roadmap Section
          _buildSectionHeader(context, 'UPCOMING PROTOCOLS'),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).primaryColor, const Color(0xFF3F42C2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'DEVELOPMENT ROADMAP',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildRoadmapItem('Advanced Encryption', '600k PBKDF2 iterations + AES-256-GCM for maximum security.', true),
                _buildRoadmapItem('File Cloud Backup', 'Backup actual vault files to Google Drive, not just settings.', false),
                _buildRoadmapItem('Biometric Unlocking', 'Seamless vault access via FaceID or Fingerprint sensors.', false),
                _buildRoadmapItem('Folder-level Nesting', 'Organize your encrypted vault into custom directories.', false),
                _buildRoadmapItem('Multi-Cloud Support', 'Additional backup options for Dropbox, OneDrive, and iCloud.', false),
                _buildRoadmapItem('Panic Protocol', 'Instant vault wipe trigger via specific gesture or remote command.', false),
              ],
            ),
          ),
          const SizedBox(height: 40),

          _buildSectionHeader(context, 'CORE TEAM'),
          _buildSectionHeader(context, 'SUPPORT THE PROJECT'),
          Card(
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.refresh_rounded, color: Theme.of(context).primaryColor, size: 22),
                  ),
                  title: const Text('Restart Guided Tour', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: const Text('Re-learn the Secura workflow', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  onTap: () {
                    ref.read(tourProvider.notifier).restartTour();
                    Navigator.pop(context);
                  },
                ),
                const Divider(height: 1, indent: 70),
                _buildSupportTile(Icons.star_rounded, 'Rate on App Store', Colors.amber),
                const Divider(height: 1, indent: 70),
                _buildSupportTile(Icons.favorite_rounded, 'Donate to Secura', Colors.red),
                const Divider(height: 1, indent: 70),
                _buildSupportTile(Icons.share_rounded, 'Invite Others', Theme.of(context).primaryColor),
              ],
            ),
          ),
          const SizedBox(height: 60),
          const Center(
            child: Text(
              'MADE WITH PRIDE • SECURA PRIVACY PROTOCOL',
              style: TextStyle(fontSize: 10, letterSpacing: 3, color: Colors.grey, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(dynamic icon, String title, String desc, {bool isFontAwesome = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Center(
              child: isFontAwesome 
                ? FaIcon(icon as FaIconData, color: Colors.grey, size: 18)
                : Icon(icon as IconData, color: Colors.grey, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTerm(String term, String definition) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
          children: [
            TextSpan(text: '$term: ', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
            TextSpan(text: definition, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          letterSpacing: 2,
          color: Colors.grey,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildSupportTile(IconData icon, String title, Color color) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: () {},
    );
  }

  Widget _buildRoadmapItem(String title, String desc, bool isNext) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isNext ? Colors.white : Colors.white.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              boxShadow: isNext ? [BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 10)] : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white, 
                    fontWeight: isNext ? FontWeight.w900 : FontWeight.w700, 
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7), 
                    fontSize: 14, 
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
