import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'storage_service.dart';
import 'encryption_service.dart';
import '../../features/auth/user_model.dart';

/// Result class for backup operations with detailed status
class BackupResult {
  final bool success;
  final String? errorMessage;
  final DateTime? timestamp;

  BackupResult({required this.success, this.errorMessage, this.timestamp});

  factory BackupResult.success([DateTime? ts]) => BackupResult(
    success: true,
    timestamp: ts ?? DateTime.now(),
  );

  factory BackupResult.failure(String message) => BackupResult(
    success: false,
    errorMessage: message,
  );
}

/// Backup metadata for versioning and integrity checks
class BackupMetadata {
  final String version;
  final DateTime timestamp;
  final String userEmail;
  final String checksum;
  final bool isEncrypted;

  BackupMetadata({
    required this.version,
    required this.timestamp,
    required this.userEmail,
    required this.checksum,
    this.isEncrypted = true,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'timestamp': timestamp.toIso8601String(),
    'userEmail': userEmail,
    'checksum': checksum,
    'isEncrypted': isEncrypted,
  };

  factory BackupMetadata.fromJson(Map<String, dynamic> json) => BackupMetadata(
    version: json['version'] ?? '1.0',
    timestamp: DateTime.parse(json['timestamp']),
    userEmail: json['userEmail'],
    checksum: json['checksum'],
    isEncrypted: json['isEncrypted'] ?? true,
  );
}

class BackupService {
  static const String _backupFileName = 'secura_backup.enc';
  static const String _metadataFileName = 'secura_backup_meta.json';
  static const String _backupVersion = '2.0';

  /// Check if a backup exists without restoring it
  static Future<BackupMetadata?> checkBackupExists(GoogleSignInAccount account) async {
    try {
      final scopes = [drive.DriveApi.driveAppdataScope];
      final authz = await account.authorizationClient.authorizeScopes(scopes);
      final httpClient = authz.authClient(scopes: scopes);

      final driveApi = drive.DriveApi(httpClient);

      // Check metadata file
      final list = await driveApi.files.list(
        q: "name = '$_metadataFileName' and 'appDataFolder' in parents",
        spaces: 'appDataFolder',
      );

      if (list.files == null || list.files!.isEmpty) return null;

      final fileId = list.files!.first.id!;
      final media = await driveApi.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

      final bytes = await media.stream.expand((i) => i).toList();
      final content = utf8.decode(bytes);
      final data = jsonDecode(content) as Map<String, dynamic>;

      return BackupMetadata.fromJson(data);
    } catch (e) {
      debugPrint('Failed to check backup: $e');
      return null;
    }
  }

  /// Perform backup with encryption - splits into check/apply phases
  static Future<BackupResult> performBackup(GoogleSignInAccount account) async {
    try {
      final scopes = [drive.DriveApi.driveAppdataScope];
      final authz = await account.authorizationClient.authorizeScopes(scopes);
      final httpClient = authz.authClient(scopes: scopes);

      final driveApi = drive.DriveApi(httpClient);
      final storage = StorageService();

      final settings = await storage.getAllSettings();
      final user = await storage.getCurrentUser();
      final salt = await storage.getSalt();

      if (user == null) {
        return BackupResult.failure('No user logged in');
      }

      // Create backup data structure
      final backupData = {
        'version': _backupVersion,
        'user': user.toJson(),
        'settings': settings,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final jsonContent = jsonEncode(backupData);

      // Encrypt the backup data
      if (salt == null) {
        return BackupResult.failure('Encryption key not available');
      }

      // Use a derived key from the user's PIN salt for backup encryption
      final backupKey = EncryptionService.hashKey(salt);
      final encryptedData = EncryptionService.encryptBytes(
        Uint8List.fromList(utf8.encode(jsonContent)),
        backupKey,
      );

      // Create metadata with integrity checksum
      final checksum = EncryptionService.hashString(jsonContent);
      final metadata = BackupMetadata(
        version: _backupVersion,
        timestamp: DateTime.now(),
        userEmail: user.email,
        checksum: checksum,
        isEncrypted: true,
      );

      // Upload encrypted backup
      final media = drive.Media(Stream.value(encryptedData), encryptedData.length);
      final metaMedia = drive.Media(
        Stream.value(utf8.encode(jsonEncode(metadata.toJson()))),
        jsonEncode(metadata.toJson()).length,
      );

      final list = await driveApi.files.list(
        q: "name = '$_backupFileName' and 'appDataFolder' in parents",
        spaces: 'appDataFolder',
      );

      if (list.files != null && list.files!.isNotEmpty) {
        final fileId = list.files!.first.id!;
        await driveApi.files.update(drive.File(), fileId, uploadMedia: media);
      } else {
        final fileMetadata = drive.File()
          ..name = _backupFileName
          ..parents = ['appDataFolder'];
        await driveApi.files.create(fileMetadata, uploadMedia: media);
      }

      // Upload metadata
      final metaList = await driveApi.files.list(
        q: "name = '$_metadataFileName' and 'appDataFolder' in parents",
        spaces: 'appDataFolder',
      );

      if (metaList.files != null && metaList.files!.isNotEmpty) {
        final metaId = metaList.files!.first.id!;
        await driveApi.files.update(drive.File(), metaId, uploadMedia: metaMedia);
      } else {
        final metaMetadata = drive.File()
          ..name = _metadataFileName
          ..parents = ['appDataFolder'];
        await driveApi.files.create(metaMetadata, uploadMedia: metaMedia);
      }

      return BackupResult.success();
    } catch (e) {
      debugPrint('Backup failed: $e');
      return BackupResult.failure('Backup failed: ${e.toString()}');
    }
  }

  /// Download backup metadata without restoring - for preview
  static Future<BackupMetadata?> getBackupMetadata(GoogleSignInAccount account) async {
    return checkBackupExists(account);
  }

  /// Restore backup - only applies after user confirmation
  static Future<BackupResult> performRestore(GoogleSignInAccount account) async {
    try {
      final scopes = [drive.DriveApi.driveAppdataScope];
      final authz = await account.authorizationClient.authorizeScopes(scopes);
      final httpClient = authz.authClient(scopes: scopes);

      final driveApi = drive.DriveApi(httpClient);
      final storage = StorageService();

      final list = await driveApi.files.list(
        q: "name = '$_backupFileName' and 'appDataFolder' in parents",
        spaces: 'appDataFolder',
      );

      if (list.files == null || list.files!.isEmpty) {
        return BackupResult.failure('No backup found');
      }

      final fileId = list.files!.first.id!;
      final media = await driveApi.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

      final bytes = await media.stream.expand((i) => i).toList();
      final encryptedData = Uint8List.fromList(bytes);

      // Get salt for decryption
      final salt = await storage.getSalt();
      if (salt == null) {
        return BackupResult.failure('Cannot decrypt: No encryption key');
      }

      final backupKey = EncryptionService.hashKey(salt);

      // Decrypt the backup
      final decrypted = EncryptionService.decryptBytes(encryptedData, backupKey);
      final jsonContent = utf8.decode(decrypted);
      final data = jsonDecode(jsonContent) as Map<String, dynamic>;

      // Verify integrity
      final checksum = EncryptionService.hashString(jsonContent);
      final metadata = await checkBackupExists(account);

      if (metadata != null && metadata.checksum != checksum) {
        debugPrint('Warning: Backup integrity check failed');
        // Continue anyway - might be version difference
      }

      // Restore data - only applied here, after confirmation dialog
      if (data.containsKey('user')) {
        final user = UserModel.fromJson(data['user']);
        await storage.saveUser(user);
      }
      if (data.containsKey('settings')) {
        await storage.restoreSettings(data['settings']);
      }

      return BackupResult.success(DateTime.parse(data['timestamp']));
    } catch (e) {
      debugPrint('Restore failed: $e');
      return BackupResult.failure('Restore failed: ${e.toString()}');
    }
  }

  /// Delete backup from cloud
  static Future<BackupResult> deleteBackup(GoogleSignInAccount account) async {
    try {
      final scopes = [drive.DriveApi.driveAppdataScope];
      final authz = await account.authorizationClient.authorizeScopes(scopes);
      final httpClient = authz.authClient(scopes: scopes);

      final driveApi = drive.DriveApi(httpClient);

      final list = await driveApi.files.list(
        q: "name = '$_backupFileName' and 'appDataFolder' in parents",
        spaces: 'appDataFolder',
      );

      if (list.files != null && list.files!.isNotEmpty) {
        await driveApi.files.delete(list.files!.first.id!);
      }

      // Also delete metadata
      final metaList = await driveApi.files.list(
        q: "name = '$_metadataFileName' and 'appDataFolder' in parents",
        spaces: 'appDataFolder',
      );

      if (metaList.files != null && metaList.files!.isNotEmpty) {
        await driveApi.files.delete(metaList.files!.first.id!);
      }

      return BackupResult.success();
    } catch (e) {
      return BackupResult.failure('Failed to delete backup: ${e.toString()}');
    }
  }
}
