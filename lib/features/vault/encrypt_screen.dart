import 'package:flutter/material.dart';

import '../../components/components.dart';

class EncryptScreen extends StatelessWidget {
  const EncryptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          AppHeader(title: 'Secura'),
          SizedBox(height: 16),
          Text('Decrypted Files', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('Ready for encryption'),
          SizedBox(height: 16),
          FileItemCard(name: 'Project_Q3_Financials.xlsx', meta: '1.2 MB • Modified 2 hours ago', encrypted: false),
          FileItemCard(name: 'Passport_Scan_HQ.png', meta: '4.5 MB • Modified yesterday', encrypted: false),
          FileItemCard(name: 'Client_Backup_Archive.zip', meta: '256 MB • Modified 3 days ago', encrypted: false),
        ],
      ),
    );
  }
}
