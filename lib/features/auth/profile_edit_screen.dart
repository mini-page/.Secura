import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/components.dart';
import 'user_provider.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _nameController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _nameController.text = ref.read(userProvider)?.name ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final cardColor = Theme.of(context).cardTheme.color ?? Colors.white;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // User Identity Card (Matching Google Sync style)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    child: Text(user?.profileEmoji ?? '👤', style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Secura User',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        Text(
                          user?.email ?? 'No Identity Attached',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text('VAULT IDENTITY', style: Theme.of(context).textTheme.titleSmall?.copyWith(letterSpacing: 1.5, color: Theme.of(context).hintColor, fontSize: 11, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Display Name',
              filled: true,
              fillColor: cardColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            enabled: false,
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: user?.email ?? '',
              filled: true,
              fillColor: cardColor.withValues(alpha: 0.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 48),
          PrimaryCtaButton(
            label: 'Save Profile',
            onPressed: () async {
              await ref.read(userProvider.notifier).updateProfile(name: _nameController.text);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
