import 'package:flutter/material.dart';
import '../core/theme/custom_theme.dart';

class ThemePresetSelector extends StatefulWidget {
  const ThemePresetSelector({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final SecuraTheme selected;
  final ValueChanged<SecuraTheme> onChanged;

  @override
  State<ThemePresetSelector> createState() => _ThemePresetSelectorState();
}

class _ThemePresetSelectorState extends State<ThemePresetSelector> {
  bool _showLightThemes = true;
  bool _showDarkThemes = true;

  @override
  Widget build(BuildContext context) {
    final lightThemes = SecuraTheme.presets.where((t) => !t.isDark).toList();
    final darkThemes = SecuraTheme.presets.where((t) => t.isDark).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Light Themes - Horizontal scroll
        _buildSectionHeader('Light Themes', !_showLightThemes, () {
          setState(() => _showLightThemes = !_showLightThemes);
        }),
        if (_showLightThemes) _buildHorizontalThemeList(lightThemes),
        const SizedBox(height: 16),

        // Dark Themes - Horizontal scroll
        _buildSectionHeader('Dark Themes', !_showDarkThemes, () {
          setState(() => _showDarkThemes = !_showDarkThemes);
        }),
        if (_showDarkThemes) _buildHorizontalThemeList(darkThemes),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isCollapsed, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(isCollapsed ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded, size: 18, color: Theme.of(context).hintColor),
            const SizedBox(width: 4),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1, color: Theme.of(context).hintColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalThemeList(List<SecuraTheme> themes) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: themes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final theme = themes[index];
          final isSelected = widget.selected.id == theme.id;
          return _ThemeChip(theme: theme, isSelected: isSelected, onTap: () => widget.onChanged(theme));
        },
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({required this.theme, required this.isSelected, required this.onTap});

  final SecuraTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor.withValues(alpha: 0.15) : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? theme.primaryColor : Theme.of(context).dividerColor, width: isSelected ? 2 : 1),
          boxShadow: isSelected ? [BoxShadow(color: theme.primaryColor.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 1)] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 22, height: 22, decoration: BoxDecoration(color: theme.primaryColor, shape: BoxShape.circle, border: Border.all(color: Theme.of(context).dividerColor, width: 1.5))),
            const SizedBox(width: 10),
            Text(theme.name, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? theme.primaryColor : Theme.of(context).textTheme.bodyMedium?.color)),
          ],
        ),
      ),
    );
  }
}

// Legacy compatibility
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({required this.selected, required this.onChanged, super.key});

  final ThemeMode selected;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _buildOption(context, ThemeMode.light, Icons.light_mode_outlined, 'Light'),
            _buildOption(context, ThemeMode.dark, Icons.dark_mode_outlined, 'Dark'),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, ThemeMode mode, IconData icon, String label) {
    final isSelected = selected == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            Icon(icon, size: 20, color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).hintColor),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).hintColor)),
          ]),
        ),
      ),
    );
  }
}