import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/components.dart';
import 'user_provider.dart';
import 'auth_screen.dart';

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _proceed() async {
    if (_phoneController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Minimal delay to show transition
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      await ref.read(userProvider.notifier).login(_phoneController.text);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthScreen(isSetup: true)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Setup Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final cardColor = Theme.of(context).cardTheme.color;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Hero(
                tag: 'app_brand',
                child: Image.asset('assets/app_brand.png', width: 80),
              ),
              const SizedBox(height: 32),
              Text(
                'Identity Setup', 
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose your preferred secure login method', 
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              
              // Phone Input (Active)
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.phone_rounded, color: primary),
                  hintText: 'Phone Number',
                  hintStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                  filled: true,
                  fillColor: cardColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20), 
                    borderSide: BorderSide(color: primary.withValues(alpha: 0.1)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryCtaButton(
                label: _isLoading ? 'Securing...' : 'Verify Phone Identity',
                onPressed: _isLoading ? null : () { _proceed(); },
              ),
              
              const SizedBox(height: 32),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w900, fontSize: 10)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 32),
              
              // Google Login (Placeholder)
              _buildPlaceholderButton(
                icon: Icons.g_mobiledata_rounded,
                label: 'Sign in with Google',
                soon: true,
              ),
              const SizedBox(height: 12),
              
              // More Options (Placeholder)
              _buildPlaceholderButton(
                icon: Icons.more_horiz_rounded,
                label: 'More Options',
                soon: true,
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderButton({required IconData icon, required String label, bool soon = false}) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Opacity(
        opacity: 0.5,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            if (soon) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('SOON', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
