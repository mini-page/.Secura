import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'encryption_service.dart';
import 'activity_logger.dart';
import '../../features/vault/vault_file_model.dart';
import '../../features/auth/user_provider.dart';

class FileVaultService {
  final Ref _ref;
  final ActivityLogger _logger = ActivityLogger();

  FileVaultService(this._ref);

  /// Internal directory that is hidden from the system's file manager and search.
  Future<Directory> get _lockerDir async {
    final baseDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(baseDir.path, '.locker_private'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Internal directory for soft-deleted files.
  Future<Directory> get _recycleDir async {
    final baseDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(baseDir.path, '.secura_recycle'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
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
    final entities = await dir.list().toList();
    final files = <VaultFile>[];

    for (var entity in entities) {
      if (entity is File) {
        final stat = await entity.stat();
        final isEncrypted = p.extension(entity.path) == '.secura';
        final rawName = isEncrypted ? p.basenameWithoutExtension(entity.path) : p.basename(entity.path);

        String originalName;
        try {
          // Decode the Base64 filename to hide from OS search
          originalName = utf8.decode(base64Url.decode(rawName));
        } catch (_) {
          originalName = rawName; // Fallback for older files
        }

        files.add(VaultFile(
          name: originalName,
          path: entity.path,
          size: stat.size,
          modified: stat.modified,
          isEncrypted: isEncrypted,
        ));
      }
    }
    files.sort((a, b) => b.modified.compareTo(a.modified));
    return files;
  }

  Future<void> addFile(File source, {required bool encrypt}) async {
    final dir = await _lockerDir;
    final originalName = p.basename(source.path);
    final encodedName = base64Url.encode(utf8.encode(originalName));

    final fileName = encrypt ? '$encodedName.secura' : encodedName;
    final targetPath = p.join(dir.path, fileName);

    try {
      if (encrypt) {
        final masterKey = _ref.read(sessionProvider);
        if (masterKey == null) throw Exception('Vault locked');

        final bytes = await source.readAsBytes();
        final encryptedBytes = EncryptionService.encryptBytes(bytes, masterKey);
        await File(targetPath).writeAsBytes(encryptedBytes);
      } else {
        await source.copy(targetPath);
      }

      _logger.logEvent(encrypt ? 'File Encrypted & Added' : 'File Added to Vault', details: originalName);

      if (await source.exists()) {
        await _secureShred(source);
      }
    } catch (e) {
      debugPrint('Add File Failure: $e');
      rethrow;
    }
  }

  /// Securely wipe file before deletion to prevent forensic recovery
  Future<void> _secureShred(File file) async {
    try {
      final length = await file.length();
      final raf = await file.open(mode: FileMode.write);

      const chunkSize = 1024 * 1024; // 1MB chunks
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
    } catch (_) {} // Ignore if lock prevents shredding

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
      final recycleDir = await _recycleDir;
      final targetPath = p.join(recycleDir.path, p.basename(file.path));
      await f.rename(targetPath);
      _logger.logEvent('File Moved to Recycle Bin', details: file.name);
    }
  }

  Future<void> permanentlyDeleteFile(VaultFile file) async {
    final f = File(file.path);
    if (await f.exists()) {
      await f.delete();
      _logger.logEvent('File Permanently Deleted', details: file.name);
    }
  }

  Future<void> restoreFromRecycleBin(VaultFile file) async {
    final f = File(file.path);
    if (await f.exists()) {
      final lockerDir = await _lockerDir;
      final targetPath = p.join(lockerDir.path, p.basename(file.path));
      await f.rename(targetPath);
      _logger.logEvent('File Restored from Recycle Bin', details: file.name);
    }
  }

  Future<void> emptyRecycleBin() async {
    final dir = await _recycleDir;
    if (await dir.exists()) {
      await for (var entity in dir.list()) {
        if (entity is File) await entity.delete();
      }
      _logger.logEvent('Recycle Bin Emptied');
    }
  }

  Future<void> encryptFile(VaultFile file) async {
    if (file.isEncrypted) return;

    final source = File(file.path);
    final bytes = await source.readAsBytes();

    final masterKey = _ref.read(sessionProvider);
    if (masterKey == null) throw Exception('Vault locked');

    final encryptedBytes = EncryptionService.encryptBytes(bytes, masterKey);
    final dir = await _lockerDir;

    final encodedName = base64Url.encode(utf8.encode(file.name));
    final targetPath = p.join(dir.path, '$encodedName.secura');

    await File(targetPath).writeAsBytes(encryptedBytes);
    await _secureShred(source);
    _logger.logEvent('File Encrypted', details: file.name);
  }

  Future<List<int>> readFile(VaultFile file) async {
    final f = File(file.path);
    if (!await f.exists()) throw Exception('File not found');

    final bytes = await f.readAsBytes();

    if (file.isEncrypted) {
      final masterKey = _ref.read(sessionProvider);
      if (masterKey == null) throw Exception('Vault locked');
      return EncryptionService.decryptBytes(bytes, masterKey);
    }
    return bytes;
  }

  Future<String> getTempDecryptedPath(VaultFile file) async {
    final bytes = await readFile(file);
    final tempDir = await getTemporaryDirectory();
    final tempPath = p.join(tempDir.path, '.tmp_view_${file.name}');
    final tempFile = File(tempPath);
    if (await tempFile.exists()) await tempFile.delete();
    await tempFile.writeAsBytes(bytes);
    _logger.logEvent('File Viewed', details: file.name);
    return tempPath;
  }

  Future<String> restoreFile(VaultFile file) async {
    final bytes = await readFile(file);

    Directory? publicDir;
    if (Platform.isAndroid) {
      publicDir = Directory('/storage/emulated/0/Download');
      if (!await publicDir.exists()) {
        final list = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        publicDir = list?.first;
      }
    } else {
      publicDir = await getApplicationDocumentsDirectory();
    }

    if (publicDir == null) throw Exception('Could not find a valid restoration directory');

    final targetPath = p.join(publicDir.path, file.name);
    var finalPath = targetPath;
    var counter = 1;
    while (await File(finalPath).exists()) {
      final nameParts = p.basenameWithoutExtension(file.name);
      final ext = p.extension(file.name);
      finalPath = p.join(publicDir.path, '${nameParts}_$counter$ext');
      counter++;
    }

    await File(finalPath).writeAsBytes(bytes);
    await deleteFile(file);
    _logger.logEvent('File Restored to Public Storage', details: file.name);
    return finalPath;
  }
}
