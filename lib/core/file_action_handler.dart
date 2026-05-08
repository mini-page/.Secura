import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

import '../components/secura_notifications.dart';
import '../components/file_item_card.dart'; // This contains FileAction
import '../features/vault/vault_file_model.dart';
import '../features/vault/vault_provider.dart';

mixin FileActionHandler {
  Future<void> handleFileAction(
    BuildContext context, 
    WidgetRef ref, 
    VaultFile file, 
    FileAction action,
  ) async {
    switch (action) {
      case FileAction.open:
        _showLoading(context);
        try {
          final path = await ref.read(fileVaultServiceProvider).getTempDecryptedPath(file);
          if (!context.mounted) return;
          Navigator.pop(context); // Close loading
          await OpenFile.open(path);
        } catch (e) {
          if (!context.mounted) return;
          Navigator.pop(context); // Close loading
          _showError(context, 'Failed to open file: $e');
        }
        break;

      case FileAction.share:
        _showLoading(context);
        try {
          final path = await ref.read(fileVaultServiceProvider).getTempDecryptedPath(file);
          if (!context.mounted) return;
          Navigator.pop(context); // Close loading
          await SharePlus.instance.share(
            ShareParams(files: [XFile(path)]),
          );
        } catch (e) {
          if (!context.mounted) return;
          Navigator.pop(context); // Close loading
          _showError(context, 'Failed to share file: $e');
        }
        break;

      case FileAction.encrypt:
        await ref.read(vaultProvider.notifier).encryptExistingFile(file);
        if (!context.mounted) return;
        _showSuccess(context, 'File encrypted successfully');
        break;

      case FileAction.restore:
        final route = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            title: const Text('Restoration Protocol', style: TextStyle(fontWeight: FontWeight.w900)), 
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Choose your restoration destination:'),
                const SizedBox(height: 16),
                _buildRouteOption(
                  context,
                  Icons.download_rounded,
                  'Local Download',
                  'Move to device Downloads folder',
                  () => Navigator.pop(context, 'local'),
                ),
                const SizedBox(height: 12),
                _buildRouteOption(
                  context,
                  Icons.cloud_upload_rounded,
                  'Cloud Sync',
                  'Securely sync to Secura Drive',
                  () {}, // No-op
                  isComingSoon: true,
                ),
              ],
            ),
          ),
        );

        if (!context.mounted) return;
        if (route == 'local') {
          _showLoading(context);
          try {
            await ref.read(fileVaultServiceProvider).restoreFile(file);
            await ref.read(vaultProvider.notifier).refresh();
            if (!context.mounted) return;
            Navigator.pop(context); // Close loading
            _showSuccess(context, 'File restored to Downloads folder');
          } catch (e) {
            if (!context.mounted) return;
            Navigator.pop(context); // Close loading
            _showError(context, 'Failed to restore file: $e');
          }
        }
        break;
      case FileAction.delete:
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete File?'),
            content: Text('Are you sure you want to delete ${file.name}?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
        if (confirm == true) {
          await ref.read(vaultProvider.notifier).deleteFile(file);
        }
        break;
    }
  }

  void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _showError(BuildContext context, String message) {
    SecuraNotifications.showError(context, message);
  }

  void _showSuccess(BuildContext context, String message) {
    SecuraNotifications.showSuccess(context, message);
  }

  Widget _buildRouteOption(
    BuildContext context, 
    IconData icon, 
    String title, 
    String sub, 
    VoidCallback onTap,
    {bool isComingSoon = false}
  ) {
    return InkWell(
      onTap: isComingSoon ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: isComingSoon ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (isComingSoon)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('SOON', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
