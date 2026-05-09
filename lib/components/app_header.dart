import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/vault/vault_provider.dart';

class AppHeader extends ConsumerStatefulWidget {
  const AppHeader({required this.title, this.showSearch = true, super.key});

  final String title;
  final bool showSearch;

  @override
  ConsumerState<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends ConsumerState<AppHeader> with SingleTickerProviderStateMixin {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 20, top: 8),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Standard Header (Fades out when searching)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isSearching ? 0.0 : 1.0,
            child: Row(
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                if (widget.showSearch)
                  IconButton(
                    onPressed: () => setState(() => _isSearching = true),
                    icon: const Icon(Icons.search_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).cardTheme.color,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
              ],
            ),
          ),
          
          // Sliding Search Bar (Slides in from left)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutQuart,
            left: _isSearching ? 0 : -MediaQuery.of(context).size.width,
            right: _isSearching ? 0 : MediaQuery.of(context).size.width,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isSearching ? 1.0 : 0.0,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: _isSearching,
                      onChanged: (value) => ref.read(searchQueryProvider.notifier).updateQuery(value),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(
                          fontWeight: FontWeight.w900, 
                          color: Colors.grey.withValues(alpha: 0.5),
                          letterSpacing: 1,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, size: 24),
                        filled: true,
                        fillColor: Theme.of(context).cardTheme.color,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      setState(() => _isSearching = false);
                      _searchController.clear();
                      ref.read(searchQueryProvider.notifier).clear();
                    },
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).cardTheme.color,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
