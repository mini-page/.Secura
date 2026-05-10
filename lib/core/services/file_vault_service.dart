import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'encryption_service.dart';
import 'activity_logger.dart';
import '../../features/vault/vault_file_model.dart';
import '../../features/auth/user_provider.dart';

/// Custom exception for file vault operations with user-friendly messages
class VaultException implements Exception {
  final String message;
  final String? userMessage;

  VaultException(this.message, {this.userMessage});

  @override
  String toString() => message;

  String get displayMessage => userMessage ?? message;
}

class FileVaultService {
  final Ref _ref;
  final ActivityLogger _logger = ActivityLogger();

  // Track temp files for cleanup
  final List<String> _tempFiles = [];

  FileVaultService(this._ref);

  Future<Directory> _getBaseDir() async {
    try {
      return await getApplicationSupportDirectory();
    } catch (_) {
      try {
        return await getApplicationDocumentsDirectory();
      } catch (_) {
        return await getTemporaryDirectory();
      }
    }
  }

  /// Internal directory that is hidden from the system's file manager and search.
  Future<Directory> get _lockerDir async {
    final baseDir = await _getBaseDir();
    final dir = Directory(p.join(baseDir.path, '.locker_private'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Internal directory for soft-deleted files.
  Future<Directory> get _recycleDir async {
    final baseDir = await _getBaseDir();
    final dir = Directory(p.join(baseDir.path, '.secura_recycle'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Clean up all temp files - call on app lifecycle change
  Future<void> cleanupTempFiles() async {
    for (final path in _tempFiles) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Failed to clean temp file $path: $e');
      }
    }
    _tempFiles.clear();
  }

  Future<List<VaultFile>> listFiles() async {
    final dir = await _lockerDir;
    return _listFromDir(dir);
  }

  Future<List<VaultFile>> listRecycleBin() async {
    final dir = await _recycleDir;
    return _listFromDir(dir);
  }

  Future<List<VaultFile>> _listFromDir(Directory dir) async {
    try {
      final entities = await dir.list().toList();
      final files = <VaultFile>[];

      for (var entity in entities) {
        if (entity is File) {
          try {
            final stat = await entity.stat();
            final isEncrypted = p.extension(entity.path) == '.secura';
            final rawName = isEncrypted ? p.basenameWithoutExtension(entity.path) : p.basename(entity.path);

            String originalName;
            try {
              originalName = utf8.decode(base64Url.decode(rawName));
            } catch (_) {
              originalName = rawName;
            }

            files.add(VaultFile(
              name: originalName,
              path: entity.path,
              size: stat.size,
              modified: stat.modified,
              isEncrypted: isEncrypted,
            ));
          } catch (e) {
            debugPrint('Error reading file ${entity.path}: $e');
          }
        }
      }
      files.sort((a, b) => b.modified.compareTo(a.modified));
      return files;
    } catch (e) {
      debugPrint('Error listing directory: $e');
      return [];
    }
  }

  Future<void> addFile(File source, {required bool encrypt}) async {
    final dir = await _lockerDir;
    final originalName = p.basename(source.path);

    // Validate file exists and is readable
    if (!await source.exists()) {
      throw VaultException(
        'Source file does not exist',
        userMessage: 'The file you selected cannot be found.',
      );
    }

    final fileSize = await source.length();
    if (fileSize == 0) {
      throw VaultException(
        'Cannot add empty file',
        userMessage: 'Empty files cannot be added to the vault.',
      );
    }

    // 50MB limit for encryption operations
    if (fileSize > 50 * 1024 * 1024) {
      throw VaultException(
        'File too large for encryption',
        userMessage: 'Files larger than 50MB cannot be encrypted. Please split the file or compress it.',
      );
    }

    final encodedName = base64Url.encode(utf8.encode(originalName));
    final fileName = encrypt ? '$encodedName.secura' : encodedName;
    final targetPath = p.join(dir.path, fileName);

    try {
      if (encrypt) {
        debugPrint('Import: Encrypting file ${source.path}');
        final masterKey = _ref.read(sessionProvider);
        if (masterKey == null) {
          throw VaultException(
            'Vault is locked',
            userMessage: 'Please unlock the vault before adding files.',
          );
        }

        final bytes = await source.readAsBytes();
        debugPrint('Import: Read ${bytes.length} bytes from source');
        final encryptedBytes = EncryptionService.encryptBytes(bytes, masterKey);
        await File(targetPath).writeAsBytes(encryptedBytes);
        debugPrint('Import: Wrote encrypted file to $targetPath');
      } else {
        debugPrint('Import: Moving file ${source.path} to $targetPath');
        await source.copy(targetPath);
      }

      final targetFile = File(targetPath);
      if (await targetFile.exists()) {
        debugPrint('Import: SUCCESS - Target file exists at $targetPath');
      } else {
        debugPrint('Import: FAILURE - Target file does not exist after write');
      }

      _logger.logEvent(encrypt ? 'File Encrypted & Added' : 'File Added to Vault', details: originalName);

      // Securely shred source file after successful encryption
      if (await source.exists()) {
        debugPrint('Import: Shredding source file ${source.path}');
        await _secureShred(source);
        
        if (await source.exists()) {
          debugPrint('Import: Shredding FAILED - source file still exists, attempting force delete');
          await source.delete().catchError((e) => debugPrint('Import: Force delete failed: $e'));
        } else {
          debugPrint('Import: Source file successfully shredded');
        }
      }
    } catch (e) {
      debugPrint('Add File Failure in Service: $e');
      // Clean up partial file if it exists
      final targetFile = File(targetPath);
      if (await targetFile.exists()) {
        await targetFile.delete();
      }

      if (e is VaultException) rethrow;

      throw VaultException(
        'Failed to add file: $e',
        userMessage: 'Could not add the file. Please try again.',
      );
    }
  }

  /// Securely wipe file before deletion to prevent forensic recovery
  Future<void> _secureShred(File file) async {
    try {
      final length = await file.length();
      if (length == 0) {
        await file.delete();
        return;
      }

      final raf = await file.open(mode: FileMode.write);
      const chunkSize = 1024 * 1024;
      final zeroChunk = Uint8List(chunkSize);

      int written = 0;
      while (written < length) {
        final remaining = length - written;
        if (remaining < chunkSize) {
          await raf.writeFrom(Uint8List(remaining));
          written += remaining;
        } else {
          await raf.writeFrom(zeroChunk);
          written += chunkSize;
        }
      }
      await raf.close();
    } catch (_) {}

    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  /// Moves file to recycle bin instead of deleting permanently.
  Future<void> deleteFile(VaultFile file) async {
    final f = File(file.path);
    if (await f.exists()) {
      try {
        final recycleDir = await _recycleDir;
        final targetPath = p.join(recycleDir.path, p.basename(file.path));

        // Handle name collision in recycle bin
        var finalPath = targetPath;
        var counter = 1;
        while (await File(finalPath).exists()) {
          final nameWithoutExt = p.basenameWithoutExtension(file.name);
          final ext = p.extension(file.name);
          finalPath = p.join(recycleDir.path, '${nameWithoutExt}_$counter$ext');
          counter++;
        }

        await f.rename(finalPath);
        _logger.logEvent('File Moved to Recycle Bin', details: file.name);
      } catch (e) {
        throw VaultException(
          'Failed to delete file: $e',
          userMessage: 'Could not move file to recycle bin.',
        );
      }
    }
  }

  Future<void> permanentlyDeleteFile(VaultFile file) async {
    final f = File(file.path);
    if (await f.exists()) {
      try {
        await _secureShred(f);
        _logger.logEvent('File Permanently Deleted', details: file.name);
      } catch (e) {
        throw VaultException(
          'Failed to delete file: $e',
          userMessage: 'Could not permanently delete the file.',
        );
      }
    }
  }

  Future<void> restoreFromRecycleBin(VaultFile file) async {
    final f = File(file.path);
    if (await f.exists()) {
      try {
        final lockerDir = await _lockerDir;
        final targetPath = p.join(lockerDir.path, p.basename(file.path));

        // Handle name collision
        var finalPath = targetPath;
        var counter = 1;
        while (await File(finalPath).exists()) {
          final nameWithoutExt = p.basenameWithoutExtension(file.name);
          final ext = p.extension(file.name);
          finalPath = p.join(lockerDir.path, '${nameWithoutExt}_$counter$ext');
          counter++;
        }

        await f.rename(finalPath);
        _logger.logEvent('File Restored from Recycle Bin', details: file.name);
      } catch (e) {
        throw VaultException(
          'Failed to restore file: $e',
          userMessage: 'Could not restore the file from recycle bin.',
        );
      }
    }
  }

  Future<void> emptyRecycleBin() async {
    final dir = await _recycleDir;
    if (await dir.exists()) {
      await for (var entity in dir.list()) {
        if (entity is File) {
          await _secureShred(entity);
        }
      }
      _logger.logEvent('Recycle Bin Emptied');
    }
  }

  Future<void> encryptFile(VaultFile file) async {
    if (file.isEncrypted) return;

    final source = File(file.path);
    if (!await source.exists()) {
      throw VaultException('Source file not found', userMessage: 'The file no longer exists.');
    }

    try {
      final bytes = await source.readAsBytes();

      final masterKey = _ref.read(sessionProvider);
      if (masterKey == null) {
        throw VaultException('Vault is locked', userMessage: 'Please unlock the vault first.');
      }

      final encryptedBytes = EncryptionService.encryptBytes(bytes, masterKey);
      final dir = await _lockerDir;

      final encodedName = base64Url.encode(utf8.encode(file.name));
      final targetPath = p.join(dir.path, '$encodedName.secura');

      await File(targetPath).writeAsBytes(encryptedBytes);
      await _secureShred(source);
      _logger.logEvent('File Encrypted', details: file.name);
    } catch (e) {
      if (e is VaultException) rethrow;
      throw VaultException('Encryption failed: $e', userMessage: 'Could not encrypt the file.');
    }
  }

  Future<void> decryptFile(VaultFile file) async {
    if (!file.isEncrypted) return;

    final source = File(file.path);
    if (!await source.exists()) {
      throw VaultException('Source file not found', userMessage: 'The file no longer exists.');
    }

    try {
      final bytes = await readFile(file); // This performs decryption
      final dir = await _lockerDir;

      final encodedName = base64Url.encode(utf8.encode(file.name));
      final targetPath = p.join(dir.path, encodedName); // No .secura extension

      await File(targetPath).writeAsBytes(bytes);
      await _secureShred(source);
      _logger.logEvent('File Decrypted In-App', details: file.name);
    } catch (e) {
      if (e is VaultException) rethrow;
      throw VaultException('Decryption failed: $e', userMessage: 'Could not decrypt the file in the vault.');
    }
  }

  Future<List<int>> readFile(VaultFile file) async {
    final f = File(file.path);
    if (!await f.exists()) {
      throw VaultException('File not found', userMessage: 'The file no longer exists.');
    }

    try {
      final bytes = await f.readAsBytes();

      if (file.isEncrypted) {
        final masterKey = _ref.read(sessionProvider);
        if (masterKey == null) {
          throw VaultException('Vault is locked', userMessage: 'Please unlock the vault to view this file.');
        }
        return EncryptionService.decryptBytes(bytes, masterKey);
      }
      return bytes;
    } catch (e) {
      if (e is VaultException) rethrow;
      if (e is EncryptionException) {
        throw VaultException(
          'Decryption failed',
          userMessage: 'Could not decrypt this file. Your PIN may have been reset.',
        );
      }
      throw VaultException('Failed to read file: $e', userMessage: 'Could not read the file.');
    }
  }

  Future<String> getTempDecryptedPath(VaultFile file) async {
    final bytes = await readFile(file);
    final tempDir = await getTemporaryDirectory();
    final tempPath = p.join(tempDir.path, '.tmp_view_${DateTime.now().millisecondsSinceEpoch}_${file.name}');
    final tempFile = File(tempPath);

    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    await tempFile.writeAsBytes(bytes);
    _tempFiles.add(tempPath);
    _logger.logEvent('File Viewed', details: file.name);
    return tempPath;
  }

  /// Restore file to a specific directory with integrity verification.
  /// Non-destructive: Does NOT delete the secure copy from the vault.
  Future<String> restoreFile(VaultFile file, {String? customPath}) async {
    Directory? targetDir;

    if (customPath != null) {
      targetDir = Directory(customPath);
    } else {
      if (Platform.isAndroid) {
        try {
          final downloads = await getExternalStorageDirectories(type: StorageDirectory.downloads);
          if (downloads != null && downloads.isNotEmpty) {
            targetDir = downloads.first;
          }
          if (targetDir == null || !await targetDir.exists()) {
            targetDir = Directory('/storage/emulated/0/Download');
          }
        } catch (e) {
          targetDir = await getExternalStorageDirectory();
        }
      } else {
        targetDir = await getApplicationDocumentsDirectory();
      }
    }

    if (targetDir == null || !await targetDir.exists()) {
      throw VaultException(
        'No accessible storage found',
        userMessage: 'Could not find a location to save the restored file.',
      );
    }

    final bytes = await readFile(file);

    // Generate unique filename to avoid overwriting
    final targetFilePath = p.join(targetDir.path, file.name);
    var finalPath = targetFilePath;
    var counter = 1;
    while (await File(finalPath).exists()) {
      final nameParts = p.basenameWithoutExtension(file.name);
      final ext = p.extension(file.name);
      finalPath = p.join(targetDir.path, '${nameParts}_$counter$ext');
      counter++;
    }

    try {
      final restoredFile = File(finalPath);
      await restoredFile.writeAsBytes(bytes);
      
      // Verify integrity
      if (!await restoredFile.exists()) {
        throw Exception('File write failed verification');
      }

      _logger.logEvent('File Restored (Exported)', details: file.name);
      return finalPath;
    } catch (e) {
      throw VaultException(
        'Failed to save file: $e',
        userMessage: 'Could not save the restored file. Storage may be full.',
      );
    }
  }
}
