import 'package:flutter/material.dart';

import '../../components/components.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppHeader(title: 'Secura'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const CircleAvatar(radius: 34, child: Icon(Icons.shield_rounded, size: 36)),
                  const SizedBox(height: 12),
                  Text('Secure Your Files', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  const Text(
                    'Upload and encrypt your sensitive files with military-grade security.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  PrimaryCtaButton(
                    label: 'Upload & Encrypt',
                    icon: Icons.upload_file_rounded,
                    onPressed: () {},
                    expand: false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Locker', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          const FileItemCard(name: 'Financial_Report_Q3_2026.pdf', meta: '2.4 MB • Modified 2 hours ago', encrypted: true),
          const FileItemCard(name: 'Passport_Scan.jpg', meta: '4.8 MB • Modified yesterday', encrypted: false),
          const FileItemCard(name: 'Tax_Returns_2025.zip', meta: '15.2 MB • Modified 3 days ago', encrypted: true),
        ],
      ),
    );
  }
}
