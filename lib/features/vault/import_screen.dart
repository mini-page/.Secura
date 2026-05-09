import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import '../../components/components.dart';
import '../../components/secura_notifications.dart';
import 'vault_provider.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  Directory? _currentDir;
  List<FileSystemEntity> _entities = [];
  bool _loading = true;
  bool _permissionGranted = false;
  
  // Search State
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.status;
      if (status.isGranted) {
        setState(() {
          _permissionGranted = true;
          _loading = true;
        });
        _loadDirectory(Directory('/storage/emulated/0'));
      } else {
        // Show rationale first as required by best practices
        if (!mounted) return;
        final bool? proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            title: const Text('All Files Access', style: TextStyle(fontWeight: FontWeight.w900)),
            content: const Text(
              'Secura needs "All Files Access" to securely import and SHRED original files from your device.\n\n'
              'Without this, Android forces hidden copies to remain on your system.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF575992),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Grant Access'),
              ),
            ],
          ),
        );

        if (proceed == true) {
          final requestStatus = await Permission.manageExternalStorage.request();
          if (requestStatus.isGranted) {
            setState(() {
              _permissionGranted = true;
              _loading = true;
            });
            _loadDirectory(Directory('/storage/emulated/0'));
          } else {
            if (!mounted) return;
            SecuraNotifications.showError(context, 'Storage access is required for secure import.');
            setState(() => _loading = false);
          }
        } else {
          setState(() => _loading = false);
        }
      }
    } else {
      setState(() => _permissionGranted = true);
      _loadDirectory(Directory.systemTemp);
    }
  }

  Future<void> _loadDirectory(Directory dir) async {
    setState(() => _loading = true);
    try {
      // Async listing to prevent UI hangs (ANR)
      final stream = dir.list();
      final list = await stream.toList();
      
      list.sort((a, b) {
        if (a is Directory && b is File) return -1;
        if (a is File && b is Directory) return 1;
        return a.path.compareTo(b.path);
      });
      
      if (!mounted) return;
      setState(() {
        _currentDir = dir;
        _entities = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      SecuraNotifications.showError(context, 'Access Denied: ${p.basename(dir.path)}');
    }
  }

  Future<void> _handleFileTap(File file) async {
    // Check file size to prevent OOM crash (Limit to 150MB for now)
    final stat = await file.stat();
    if (stat.size > 150 * 1024 * 1024) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('File Too Large', style: TextStyle(fontWeight: FontWeight.w900)),
          content: const Text('For security and stability, Secura currently limits imports to 150MB per file to prevent memory exhaustion.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    final bool? encrypt = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: const Text('Secura Import', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Importing "${p.basename(file.path)}" will securely DELETE (Shred) the original file from the system.\n\nEncrypt it now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Just Move', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF575992),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Encrypt', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (encrypt != null) {
      if (!mounted) return;
      
      // Use showDialog with a custom barrier for a cleaner transition
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.7),
        builder: (context) => PopScope(
          canPop: false,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Securing File...', 
                    style: TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.w900, 
                      fontSize: 16,
                      letterSpacing: 1,
                    )
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.basename(file.path),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        await ref.read(vaultProvider.notifier).addFile(file, encrypt: encrypt);
        if (!mounted) return;
        Navigator.pop(context); // close progress
        Navigator.pop(context); // go back to vault
        SecuraNotifications.showSuccess(context, 'File imported and original shredded.');
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // close progress
        SecuraNotifications.showError(context, 'Import failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRoot = _currentDir != null && (_currentDir!.path == '/storage/emulated/0' || _currentDir!.path == '/');
    
    // Filter entities based on search query
    final filteredEntities = _entities.where((entity) {
      if (_searchQuery.isEmpty) return true;
      final name = p.basename(entity.path).toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom Modern Header with Search
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: 60,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Standard Header
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _isSearching ? 0.0 : 1.0,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (_currentDir != null && !isRoot) {
                                _loadDirectory(_currentDir!.parent);
                              } else {
                                Navigator.pop(context);
                              }
                            },
                            icon: Icon(isRoot ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context).cardTheme.color,
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Import Files',
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
                                ),
                                Text(
                                  _currentDir == null 
                                      ? 'Loading...' 
                                      : (isRoot ? 'Device Root' : p.basename(_currentDir!.path)),
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
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

                    // Sliding Search Bar
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
                                onChanged: (value) => setState(() => _searchQuery = value),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                                decoration: InputDecoration(
                                  hintText: 'Search in folder',
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
                                setState(() {
                                  _isSearching = false;
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
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
              ),
            ),

            Expanded(
              child: !_permissionGranted
                  ? _buildPermissionGate()
                  : _loading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredEntities.isEmpty
                          ? _buildEmptyState()
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              physics: const BouncingScrollPhysics(),
                              itemCount: filteredEntities.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final entity = filteredEntities[index];
                                final isDir = entity is Directory;
                                final name = p.basename(entity.path);

                                // hide hidden files
                                if (name.startsWith('.')) return const SizedBox();

                                return _buildEntityCard(entity, isDir, name);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntityCard(FileSystemEntity entity, bool isDir, String name) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (isDir) {
            _loadDirectory(entity as Directory);
          } else {
            _handleFileTap(entity as File);
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isDir ? Colors.amber : Theme.of(context).primaryColor).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isDir ? Icons.folder_rounded : Icons.insert_drive_file_rounded,
                  color: isDir ? Colors.amber : Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isDir)
                      FutureBuilder<FileStat>(
                        future: entity.stat(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
                          final size = (snapshot.data!.size / 1024).toStringAsFixed(1);
                          return Text(
                            '$size KB',
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              Icon(
                isDir ? Icons.arrow_forward_ios_rounded : Icons.add_circle_outline_rounded,
                size: 16,
                color: Theme.of(context).hintColor.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionGate() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security_rounded, size: 80, color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
            const SizedBox(height: 24),
            const Text(
              'Storage Access Required',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Secura needs permission to access your files for secure encryption.',
              style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            PrimaryCtaButton(
              label: 'Grant Access',
              onPressed: _checkPermission,
              expand: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded, size: 64, color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'This folder is empty',
            style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
