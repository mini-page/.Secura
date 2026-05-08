import 'package:flutter/material.dart';

import '../../components/components.dart';
import '../auth/google_auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;


  static const _pages = [
    (
      'Welcome to Secura',
      'The Locker Concept',
      'A secure encrypted folder created on your device for sensitive files.',
      Icons.lock_rounded,
    ),
    (
      'Military Grade Encryption',
      'Local First Privacy',
      'Before files leave your hands, they are encrypted with strong protection.',
      Icons.shield_rounded,
    ),
    (
      'Total Control',
      'Your keys, your access.',
      'Only you can decrypt your files with PIN/biometric-secured access.',
      Icons.key_rounded,
    ),
    (
      'Important Warning',
      'Local Storage Only',
      'Files imported in Secura are safe, but uninstalling without recovering files leads to permanent loss. They are NOT recoverable.',
      Icons.warning_amber_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, i) {
                    final page = _pages[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (i == 0)
                          Image.asset('assets/app_brand.png', width: 128, height: 128)
                        else
                          CircleAvatar(
                            radius: 64, 
                            backgroundColor: i == 3 ? Colors.orange.withValues(alpha: 0.1) : null,
                            child: Icon(page.$4, size: 56, color: i == 3 ? Colors.orange : null),
                          ),
                        const SizedBox(height: 24),
                        Text(
                          page.$1, 
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: i == 3 ? Colors.orange : null,
                            fontWeight: FontWeight.w900,
                          ), 
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(page.$2, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Text(page.$3, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    );
                  },
                ),
              ),
              OnboardingPageIndicator(count: _pages.length, current: _index),
              const SizedBox(height: 20),
              PrimaryCtaButton(
                label: _index == _pages.length - 1 ? 'Get Started' : 'Next',
                onPressed: _index == _pages.length - 1
                    ? () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const GoogleAuthScreen()),
                        );
                      }
                    : () => _controller.nextPage(duration: const Duration(milliseconds: 220), curve: Curves.easeOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
