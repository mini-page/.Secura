import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/storage_service.dart';
import '../auth/user_model.dart';
import '../../core/services/google_auth_service.dart';
import '../../core/services/backup_service.dart';

final sessionProvider = NotifierProvider<SessionNotifier, String?>(SessionNotifier.new);

class SessionNotifier extends Notifier<String?> {
  @override
  String? build() {
    return null;
  }

  void setSession(String? session) {
    state = session;
  }

  void clearSession() {
    state = null;
  }
}

final userProvider = NotifierProvider<UserNotifier, UserModel?>(UserNotifier.new);

class UserNotifier extends Notifier<UserModel?> {
  @override
  UserModel? build() {
    _storage = StorageService();
    loadUser();
    return null;
  }

  late final StorageService _storage;

  Future<void> loadUser() async {
    state = await _storage.getCurrentUser();
  }

  Future<void> login(String email, {String? name}) async {
    final existing = await _storage.getUser(email);
    if (existing != null) {
      state = existing;
      await _storage.saveUser(existing);
    } else {
      final newUser = UserModel(email: email, name: name ?? 'New User');
      await _storage.saveUser(newUser);
      state = newUser;
    }
    _triggerBackup();
  }

  Future<void> updateProfile({String? name, String? emoji}) async {
    if (state == null) return;
    final updated = state!.copyWith(name: name, profileEmoji: emoji);
    await saveUser(updated);
  }

  Future<void> saveUser(UserModel user) async {
    await _storage.saveUser(user);
    state = user;
    _triggerBackup();
  }

  void _triggerBackup() {
    final account = GoogleAuthService.currentUser;
    if (account != null) {
      BackupService.performBackup(account);
    }
  }
}
