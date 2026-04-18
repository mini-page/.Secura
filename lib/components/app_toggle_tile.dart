import 'package:flutter/material.dart';

class AppToggleTile extends StatelessWidget {
  const AppToggleTile({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.onChanged,
    super.key,
  });

  final bool value;
  final String title;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
