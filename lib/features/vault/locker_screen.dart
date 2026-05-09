import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/components.dart';
import 'vault_provider.dart';
import '../../core/file_action_handler.dart';

class LockerScreen extends ConsumerWidget with FileActionHandler {
  const LockerScreen({super.key});

  Future<void> _onRefresh(WidgetRef ref) async {
    await ref.read(vaultProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultState = ref.watch(filteredVaultProvider);
    final isBatchMode = ref.watch(batchModeProvider);
    final selectedFiles = ref.watch(selectedFilesProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _onRefresh(ref),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const AppHeader(title: 'Locker'),
                    
                    // Locker Header with Batch Controls
                    vaultState.when(
                      data: (files) {
                        final totalBytes = files.fold<int>(0, (sum, file) => sum + file.size);
                        final usedMB = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
                        final fileCount = files.length;
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isBatchMode)
                              _buildBatchHeader(context, ref, selectedFiles.length)
                            else
                              _buildStandardHeader(context, ref, fileCount, usedMB),
                              
                            const SizedBox(height: 16),
                            
                            // Filters
                            _buildFilters(context, ref),
                            
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                      loading: () => const SizedBox(height: 100),
                      error: (_, __) => const SizedBox(),
                    ),
                  ]),
                ),
              ),

              // File List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: vaultState.when(
                  data: (files) {
                    if (files.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 100),
                          child: _buildEmptyState(context, ref),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final file = files[index];
                          return FileItemCard(
                            file: file,
                            index: index,
                            isSelected: selectedFiles.contains(file.path),
                            onSelect: isBatchMode ? (selected) {
                              ref.read(selectedFilesProvider.notifier).toggle(file.path);
                            } : null,
                            onAction: (action) => handleFileAction(context, ref, file, action),
                          );
                        },
                        childCount: files.length,
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => SliverToBoxAdapter(
                    child: Center(child: Text('Error: $err')),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      bottomSheet: isBatchMode && selectedFiles.isNotEmpty 
          ? _BatchActionBar(selectedCount: selectedFiles.length) 
          : null,
    );
  }

  Widget _buildStandardHeader(BuildContext context, WidgetRef ref, int count, String mb) {
    return Row(
      children: [
        Text('VAULT STORAGE', style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w900, 
          letterSpacing: 4, 
          color: Theme.of(context).hintColor, 
          fontSize: 12
        )),
        const Spacer(),
        IconButton(
          onPressed: () => ref.read(batchModeProvider.notifier).enable(),
          icon: const Icon(Icons.checklist_rounded, size: 18),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          color: Theme.of(context).hintColor,
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$count files • $mb MB', style: TextStyle(
            fontSize: 11, 
            fontWeight: FontWeight.w800, 
            color: Theme.of(context).colorScheme.onPrimaryContainer
          )),
        ),
      ],
    );
  }

  Widget _buildBatchHeader(BuildContext context, WidgetRef ref, int selectedCount) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.close_rounded, size: 20),
          onPressed: () {
            ref.read(batchModeProvider.notifier).disable();
            ref.read(selectedFilesProvider.notifier).clear();
          },
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(width: 8),
        Text(
          '$selectedCount selected',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => ref.read(selectedFilesProvider.notifier).clear(),
          child: const Text('Clear', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(vaultFilterProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: VaultFilter.values.map((filter) {
          final isSelected = currentFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(filter == VaultFilter.all ? 'All' : (filter == VaultFilter.encrypted ? 'Encrypted' : 'Decrypted')),
              onSelected: (_) => ref.read(vaultFilterProvider.notifier).setFilter(filter),
              labelStyle: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.w800, 
                color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).hintColor
              ),
              selectedColor: Theme.of(context).primaryColor,
              checkmarkColor: Theme.of(context).colorScheme.onPrimary,
              side: BorderSide(color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).dividerColor),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_rounded, size: 72, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 32),
          Text('Your Locker is Empty', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text('Add files to keep them secure', style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      ),
    );
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
          Expanded(child: _BatchButton(icon: Icons.lock_rounded, label: 'Encrypt', onTap: () async {
            final count = await ref.read(vaultProvider.notifier).batchEncrypt(selectedFileList);
            if (context.mounted) {
              ref.read(selectedFilesProvider.notifier).clear();
              ref.read(batchModeProvider.notifier).disable();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$count files encrypted')));
            }
          })),
          const SizedBox(width: 12),
          Expanded(child: _BatchButton(icon: Icons.delete_outline_rounded, label: 'Delete', isDestructive: true, onTap: () async {
            final confirm = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
              title: const Text('Delete Files'),
              content: Text('Delete $selectedCount files?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
              ]
            ));
            if (confirm == true) {
              final count = await ref.read(vaultProvider.notifier).batchDelete(selectedFileList);
              if (context.mounted) {
                ref.read(selectedFilesProvider.notifier).clear();
                ref.read(batchModeProvider.notifier).disable();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$count files deleted')));
              }
            }
          })),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14), 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, 
            children: [
              Icon(icon, size: 20, color: isDestructive ? Colors.red : Theme.of(context).primaryColor), 
              const SizedBox(width: 8), 
              Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: isDestructive ? Colors.red : Theme.of(context).primaryColor))
            ]
          )
        ),
      ),
    );
  }
}
