import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
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

  @override
  void initState() {
    super.initState();
    _checkPermission();
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Storage access is required for secure import.')),
            );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Access Denied: ${p.basename(dir.path)}')),
      );
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
      // Show blocking progress overlay
      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        pageBuilder: (_, __, ___) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF575992)),
              SizedBox(height: 16),
              Text('Securing File...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.none, fontSize: 14)),
            ],
          ),
        ),
      );

      try {
        await ref.read(vaultProvider.notifier).addFile(file, encrypt: encrypt);
        if (!mounted) return;
        Navigator.pop(context); // close progress
        Navigator.pop(context); // go back to vault
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File imported and original shredded.')),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // close progress
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Securely', style: TextStyle(fontWeight: FontWeight.w900)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentDir != null && _currentDir!.path != '/storage/emulated/0' && _currentDir!.path != '/') {
              _loadDirectory(_currentDir!.parent);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: !_permissionGranted
          ? Center(
              child: ElevatedButton(
                onPressed: _checkPermission,
                child: const Text('Grant Storage Access'),
              ),
            )
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _entities.length,
                  itemBuilder: (context, index) {
                    final entity = _entities[index];
                    final isDir = entity is Directory;
                    final name = p.basename(entity.path);

                    // hide hidden files
                    if (name.startsWith('.')) return const SizedBox();

                    return ListTile(
                      leading: Icon(
                        isDir ? Icons.folder_rounded : Icons.insert_drive_file_rounded,
                        color: isDir ? Colors.amber : Colors.grey,
                      ),
                      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () {
                        if (isDir) {
                          _loadDirectory(entity);
                        } else {
                          _handleFileTap(entity as File);
                        }
                      },
                    );
                  },
                ),
    );
  }
}
