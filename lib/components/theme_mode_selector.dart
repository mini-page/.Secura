import 'package:flutter/material.dart';
import '../core/theme/custom_theme.dart';

class ModernThemeSelector extends StatelessWidget {
  const ModernThemeSelector({
    required this.selectedTheme,
    required this.onModeChanged,
    required this.onColorChanged,
    super.key,
  });

  final SecuraTheme selectedTheme;
  final ValueChanged<ThemeMode> onModeChanged;
  final ValueChanged<String> onColorChanged;

  @override
  Widget build(BuildContext context) {
    // Extract unique color bases from presets
    final colorBases = <String>{};
    for (final theme in SecuraTheme.presets) {
      colorBases.add(theme.id.split('_')[0]);
    }

    final isDark = selectedTheme.isDark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Theme Mode Row - Full Width
            Container(
              height: 52,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildModeButton(
                      context,
                      isSelected: !isDark,
                      icon: Icons.light_mode_rounded,
                      label: 'Light',
                      onTap: () => onModeChanged(ThemeMode.light),
                    ),
                  ),
                  Expanded(
                    child: _buildModeButton(
                      context,
                      isSelected: isDark,
                      icon: Icons.dark_mode_rounded,
                      label: 'Dark',
                      onTap: () => onModeChanged(ThemeMode.dark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Accent Color Row - Full Width
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: colorBases.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final baseId = colorBases.elementAt(index);
                  final theme = SecuraTheme.presets.firstWhere(
                    (t) => t.id.startsWith(baseId) && t.isDark == isDark,
                  );
                  final isSelected = selectedTheme.id.startsWith(baseId);

                  return GestureDetector(
                    onTap: () => onColorChanged(baseId),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.primaryColor,
                        border: isSelected
                            ? Border.all(
                                color: theme.primaryColor.withValues(alpha: 0.3),
                                width: 4,
                                strokeAlign: BorderSide.strokeAlignOutside,
                              )
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 18,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context, {
    required bool isSelected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center, // Center content in Expanded
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).cardTheme.color : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Center items horizontally
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).hintColor,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
