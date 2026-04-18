import 'package:flutter/material.dart';

import '../../components/components.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.initialTheme,
    required this.onThemeChanged,
    super.key,
  });

  final ThemeMode initialTheme;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ThemeMode _selectedTheme;
  bool _appLock = true;

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.initialTheme;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppHeader(title: 'Secura'),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline_rounded)),
              title: const Text('Alex Morgan'),
              subtitle: const Text('alex.morgan@example.com\nPREMIUM USER'),
              isThreeLine: true,
            ),
          ),
          const SizedBox(height: 20),
          Text('SECURITY', style: Theme.of(context).textTheme.titleMedium?.copyWith(letterSpacing: 2)),
          const SizedBox(height: 10),
          AppToggleTile(
            value: _appLock,
            onChanged: (value) => setState(() => _appLock = value),
            title: 'App Lock',
            subtitle: 'Require PIN to open Secura',
          ),
          const SizedBox(height: 20),
          Text('APPEARANCE', style: Theme.of(context).textTheme.titleMedium?.copyWith(letterSpacing: 2)),
          const SizedBox(height: 10),
          ThemeModeSelector(
            selected: _selectedTheme,
            onChanged: (newTheme) {
              setState(() => _selectedTheme = newTheme);
              widget.onThemeChanged(newTheme);
            },
          ),
        ],
      ),
    );
  }
}
