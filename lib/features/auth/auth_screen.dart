import 'package:flutter/material.dart';

import '../../components/components.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({required this.onAuthenticated, super.key});

  final VoidCallback onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignup = false;
  String _profession = 'Student';

  final professions = const [
    'Student',
    'Working Professional',
    'Teacher',
    'Designer',
    'Developer',
    'Doctor',
    'Lawyer',
    'Freelancer',
    'Business Owner',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Secura')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Login')),
              ButtonSegment(value: true, label: Text('Sign Up')),
            ],
            selected: {_isSignup},
            onSelectionChanged: (selection) => setState(() => _isSignup = selection.first),
          ),
          const SizedBox(height: 20),
          if (_isSignup) ...[
            const TextField(decoration: InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
          ],
          const TextField(decoration: InputDecoration(labelText: 'Email Address')),
          const SizedBox(height: 12),
          const TextField(obscureText: true, decoration: InputDecoration(labelText: 'Password')),
          if (_isSignup) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _profession,
              decoration: const InputDecoration(labelText: 'Profession'),
              items: professions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (value) => setState(() => _profession = value ?? _profession),
            ),
            if (_profession == 'Other') ...[
              const SizedBox(height: 12),
              const TextField(decoration: InputDecoration(labelText: 'Other Profession')),
            ],
          ],
          const SizedBox(height: 20),
          PrimaryCtaButton(
            label: _isSignup ? 'Create Account' : 'Continue',
            onPressed: widget.onAuthenticated,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.fingerprint),
            label: const Text('Use Biometrics'),
          ),
        ],
      ),
    );
  }
}
