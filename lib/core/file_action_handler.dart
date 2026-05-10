import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

import 'package:file_picker/file_picker.dart';
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

      case FileAction.decrypt:
        await ref.read(vaultProvider.notifier).decryptExistingFile(file);
        if (!context.mounted) return;
        _showSuccess(context, 'File decrypted successfully');
        break;

      case FileAction.restore:
        final route = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            title: const Text('Export Protocol', style: TextStyle(fontWeight: FontWeight.w900)), 
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Choose where to export a decrypted copy:'),
                const SizedBox(height: 16),
                _buildRouteOption(
                  context,
                  Icons.download_rounded,
                  'Default Downloads',
                  'Export to system Downloads folder',
                  () => Navigator.pop(context, 'local'),
                ),
                const SizedBox(height: 12),
                _buildRouteOption(
                  context,
                  Icons.folder_open_rounded,
                  'Custom Folder',
                  'Choose a specific folder on your device',
                  () => Navigator.pop(context, 'custom'),
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

        String? selectedPath;
        if (route == 'custom') {
          try {
            // Direct static access in version 11.x
            selectedPath = await FilePicker.getDirectoryPath();
            if (selectedPath == null) return; // User cancelled
          } catch (e) {
            if (!context.mounted) return;
            _showError(context, 'Permission denied or folder inaccessible.');
            return;
          }
        }

        _showLoading(context);
        try {
          // Pass the WidgetRef to access providers inside restoreFile if needed
          await ref.read(fileVaultServiceProvider).restoreFile(file, customPath: selectedPath);
          await ref.read(vaultProvider.notifier).refresh();
          
          if (!context.mounted) return;
          Navigator.pop(context); // Close loading
          
          _showSuccess(context, 'File exported successfully');
        } catch (e) {
          if (!context.mounted) return;
          Navigator.pop(context); // Close loading
          _showError(context, 'Failed to export file: $e');
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

      case FileAction.info:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.insert_drive_file_rounded, color: Theme.of(context).colorScheme.primary, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(file.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(file.sizeString, style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _buildInfoRow(context, 'Status', file.isEncrypted ? '🔒 Encrypted' : '🔓 Decrypted'),
                const SizedBox(height: 12),
                _buildInfoRow(context, 'Modified', _formatDate(file.modified)),
                const SizedBox(height: 12),
                _buildInfoRow(context, 'Path', file.path, isPath: true),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
        break;
    }
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {bool isPath = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Theme.of(context).hintColor, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: isPath ? 12 : 14, fontWeight: FontWeight.w600, color: isPath ? Theme.of(context).hintColor : null), maxLines: isPath ? 2 : 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
