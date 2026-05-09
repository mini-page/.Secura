import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/components.dart';
import '../../components/shimmer_card.dart';
import '../../core/file_action_handler.dart';
import 'vault_provider.dart';
import 'import_screen.dart';

class HomeScreen extends ConsumerWidget with FileActionHandler {
  const HomeScreen({super.key});

  void _openImportScreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ImportScreen()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultState = ref.watch(filteredVaultProvider);
    final isBatchMode = ref.watch(batchModeProvider);
    final selectedFiles = ref.watch(selectedFilesProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
          children: [
            if (isBatchMode)
              Container(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(children: [
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () { ref.read(batchModeProvider.notifier).disable(); ref.read(selectedFilesProvider.notifier).clear(); }),
                  const SizedBox(width: 8),
                  Text('${selectedFiles.length} selected', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  const Spacer(),
                  TextButton(onPressed: () => ref.read(selectedFilesProvider.notifier).clear(), child: const Text('Clear')),
                ]),
              )
            else
              Row(children: [
                Text('Secura', style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
                const Spacer(),
                IconButton(onPressed: () => ref.read(batchModeProvider.notifier).enable(), icon: const Icon(Icons.checklist_rounded), style: IconButton.styleFrom(backgroundColor: Theme.of(context).cardTheme.color, padding: const EdgeInsets.all(12))),
              ]),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
              ),
              child: ShimmerCard(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(children: [
                      Image.asset('assets/app_brand.png', width: 110),
                      const SizedBox(height: 16),
                      const _AnimatedToggleText(),
                      const SizedBox(height: 12),
                      const Text('Move sensitive files to your private vault in seconds.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 24),
                      PrimaryCtaButton(label: 'Add New File', icon: Icons.add_rounded, onPressed: () => _openImportScreen(context), expand: true),
                    ]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(children: [
              Text('LOCKER', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 4, color: Theme.of(context).hintColor, fontSize: 12)),
              const Spacer(),
              _FilterChips(),
            ]),
            const SizedBox(height: 16),
            vaultState.when(
              data: (files) {
                if (files.isEmpty) return Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 60), child: Text('Your locker is empty', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).hintColor))));
                return Column(children: files.map((file) => FileItemCard(
                  file: file,
                  index: files.indexOf(file),
                  isSelected: selectedFiles.contains(file.path),
                  onSelect: isBatchMode ? (selected) { ref.read(selectedFilesProvider.notifier).toggle(file.path); } : null,
                  onAction: (action) => handleFileAction(context, ref, file, action),
                )).toList());
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: isBatchMode && selectedFiles.isNotEmpty ? _BatchActionBar(selectedCount: selectedFiles.length) : null,
    );
  }
}

class _AnimatedToggleText extends StatelessWidget {
  const _AnimatedToggleText();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Secure Your Life',
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w900,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _FilterChips extends ConsumerWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(vaultFilterProvider);
    return Row(mainAxisSize: MainAxisSize.min, children: VaultFilter.values.map((filter) {
      final isSelected = currentFilter == filter;
      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: GestureDetector(
          onTap: () => ref.read(vaultFilterProvider.notifier).setFilter(filter),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).dividerColor),
            ),
            child: Text(filter == VaultFilter.all ? 'All' : (filter == VaultFilter.encrypted ? 'Encrypted' : 'Decrypted'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).hintColor)),
          ),
        ),
      );
    }).toList());
  }
}

class _BatchActionBar extends ConsumerWidget {
  final int selectedCount;
  const _BatchActionBar({required this.selectedCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultState = ref.watch(filteredVaultProvider);
    final files = vaultState.whenOrNull(data: (f) => f) ?? [];
    final selectedPaths = ref.watch(selectedFilesProvider);
    final selectedFileList = files.where((f) => selectedPaths.contains(f.path)).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(children: [
          Expanded(child: _BatchButton(icon: Icons.lock_rounded, label: 'Encrypt', onTap: () async { final count = await ref.read(vaultProvider.notifier).batchEncrypt(selectedFileList); if (context.mounted) { ref.read(selectedFilesProvider.notifier).clear(); ref.read(batchModeProvider.notifier).disable(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$count files encrypted'))); } })),
          const SizedBox(width: 12),
          Expanded(child: _BatchButton(icon: Icons.delete_outline_rounded, label: 'Delete', isDestructive: true, onTap: () async { final confirm = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Delete Files'), content: Text('Delete $selectedCount files?'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red)))])); if (confirm == true) { final count = await ref.read(vaultProvider.notifier).batchDelete(selectedFileList); if (context.mounted) { ref.read(selectedFilesProvider.notifier).clear(); ref.read(batchModeProvider.notifier).disable(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$count files deleted'))); } } })),
        ]),
      ),
    );
  }
}

class _BatchButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  const _BatchButton({required this.icon, required this.label, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDestructive ? Colors.red.withValues(alpha: 0.1) : Theme.of(context).primaryColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 20, color: isDestructive ? Colors.red : Theme.of(context).primaryColor), const SizedBox(width: 8), Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: isDestructive ? Colors.red : Theme.of(context).primaryColor))])),
      ),
    );
  }
}