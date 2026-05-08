import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'storage_service.dart';
import '../../features/auth/user_model.dart';

class BackupService {
  static const String _backupFileName = 'secura_backup.json';

  static Future<void> performBackup(GoogleSignInAccount account) async {
    try {
      final scopes = [drive.DriveApi.driveAppdataScope];
      final authz = await account.authorizationClient.authorizeScopes(scopes);
      final httpClient = authz.authClient(scopes: scopes);

      final driveApi = drive.DriveApi(httpClient);
      final storage = StorageService();
      
      final settings = await storage.getAllSettings();
      final user = await storage.getCurrentUser();
      
      if (user == null) return;

      final backupData = {
        'user': user.toJson(),
        'settings': settings,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final content = jsonEncode(backupData);
      final media = drive.Media(Stream.value(utf8.encode(content)), content.length);

      // Check if file exists
      final list = await driveApi.files.list(
        q: "name = '$_backupFileName' and 'appDataFolder' in parents",
        spaces: 'appDataFolder',
      );

      if (list.files != null && list.files!.isNotEmpty) {
        // Update existing
        final fileId = list.files!.first.id!;
        await driveApi.files.update(drive.File(), fileId, uploadMedia: media);
      } else {
        // Create new
        final fileMetadata = drive.File()
          ..name = _backupFileName
          ..parents = ['appDataFolder'];
        await driveApi.files.create(fileMetadata, uploadMedia: media);
      }
    } catch (e) {
      // Log or handle error
    }
  }

  static Future<bool> performRestore(GoogleSignInAccount account) async {
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

      if (list.files == null || list.files!.isEmpty) return false;

      final fileId = list.files!.first.id!;
      final media = await driveApi.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      
      final bytes = await media.stream.expand((i) => i).toList();
      final content = utf8.decode(bytes);
      final data = jsonDecode(content) as Map<String, dynamic>;

      if (data.containsKey('user')) {
        final user = UserModel.fromJson(data['user']);
        await storage.saveUser(user);
      }
      if (data.containsKey('settings')) {
        await storage.restoreSettings(data['settings']);
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
}
