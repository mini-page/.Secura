import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                const Text('V1.0.0 STABLE', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12)),
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
                _buildRoadmapItem('Real OAuth / Google Auth', 'Native integration for server-side identity verification.', true),
                _buildRoadmapItem('Server-side Sync (MySQL)', 'Robust synchronization across all your mobile devices.', false),
                _buildRoadmapItem('Encrypted Cloud Drive', 'Seamless integration with Google Drive & Dropbox.', false),
                _buildRoadmapItem('Email-based OTP Recovery', 'Secure account recovery protocols via SMTP.', false),
              ],
            ),
          ),
          const SizedBox(height: 40),

          _buildSectionHeader(context, 'DEVELOPER'),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(Icons.code_rounded, color: Colors.white),
              ),
              title: const Text('Secura Core Team', style: TextStyle(fontWeight: FontWeight.w900)),
              subtitle: const Text('Privacy-first engineering.', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 32),

          _buildSectionHeader(context, 'SUPPORT THE PROJECT'),
          Card(
            child: Column(
              children: [
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
