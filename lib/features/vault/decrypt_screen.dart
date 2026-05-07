import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/components.dart';
import '../../core/file_action_handler.dart';
import 'vault_provider.dart';

class DecryptScreen extends ConsumerWidget with FileActionHandler {
  const DecryptScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultState = ref.watch(filteredVaultProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(
          decelerationRate: ScrollDecelerationRate.fast,
        ),
        children: [
          const AppHeader(title: 'Encrypted'),
          const SizedBox(height: 16),
          const Text('SECURED VAULT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.grey)),
          const SizedBox(height: 16),
          vaultState.when(
            data: (files) {
              final encryptedFiles = files.where((f) => f.isEncrypted).toList();
              if (encryptedFiles.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text('No encrypted files.', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                );
              }
              return Column(
                children: encryptedFiles.asMap().entries.map((entry) => FileItemCard(
                  file: entry.value,
                  index: entry.key,
                  onAction: (action) => handleFileAction(context, ref, entry.value, action),
                )).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
