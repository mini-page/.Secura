import 'package:flutter/material.dart';

class FileItemCard extends StatelessWidget {
  const FileItemCard({
    required this.name,
    required this.meta,
    required this.encrypted,
    super.key,
  });

  final String name;
  final String meta;
  final bool encrypted;

  @override
  Widget build(BuildContext context) {
    final label = encrypted ? 'Encrypted' : 'Decrypted';
    final action = encrypted ? 'Decrypt' : 'Encrypt';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.insert_drive_file_outlined)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(label: Text(label)),
              ],
            ),
            const SizedBox(height: 8),
            Text(meta),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () {},
                icon: Icon(encrypted ? Icons.lock_open_rounded : Icons.lock_rounded),
                label: Text(action),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
