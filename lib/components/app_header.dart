import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    required this.title,
    this.onSearchTap,
    this.showSearch = true,
    super.key,
  });

  final String title;
  final VoidCallback? onSearchTap;
  final bool showSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
        if (showSearch)
          IconButton(
            onPressed: onSearchTap ?? () {},
            icon: const Icon(Icons.search_rounded),
          ),
      ],
    );
  }
}
