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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ImportScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultState = ref.watch(filteredVaultProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(
          decelerationRate: ScrollDecelerationRate.fast,
        ),
        children: [
          const AppHeader(title: 'Secura'),
          const SizedBox(height: 8),
          
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            ),
            child: ShimmerCard(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Image.asset('assets/app_brand.png', width: 110),
                      const SizedBox(height: 16),
                      Text('Secure Your Life', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 12),
                      const Text(
                        'Move sensitive files to your private vault in seconds.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 24),
                      PrimaryCtaButton(
                        label: 'Add New File',
                        icon: Icons.add_rounded,
                        onPressed: () => _openImportScreen(context),
                        expand: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          Text(
            'LOCKER', 
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900, 
              letterSpacing: 4, 
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          
          vaultState.when(
            data: (files) {
              if (files.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Text('Your locker is empty', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                );
              }
              return Column(
                children: List.generate(files.length, (index) {
                  final file = files[index];
                  return FileItemCard(
                    file: file,
                    index: index,
                    onAction: (action) => handleFileAction(context, ref, file, action),
                  );
                }),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
          const SizedBox(height: 100), // Extra space for floating nav
        ],
      ),
    );
  }
}
