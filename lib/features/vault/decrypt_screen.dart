import 'package:flutter/material.dart';

import '../../components/components.dart';

class DecryptScreen extends StatelessWidget {
  const DecryptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          AppHeader(title: 'Secura'),
          SizedBox(height: 16),
          Text('Encrypted Files', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('View and manage your securely encrypted files.'),
          SizedBox(height: 16),
          FileItemCard(name: 'Financial_Q3_Report.pdf', meta: '2.4 MB • Modified Oct 12, 2025', encrypted: true),
          FileItemCard(name: 'Passport_Scans.zip', meta: '15.8 MB • Modified Sep 05, 2025', encrypted: true),
          FileItemCard(name: 'Confidential_Meeting.mp4', meta: '850 MB • Modified Dec 15, 2025', encrypted: true),
        ],
      ),
    );
  }
}
