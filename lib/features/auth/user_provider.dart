import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/storage_service.dart';
import '../auth/user_model.dart';
import '../../core/services/google_auth_service.dart';

final sessionProvider = NotifierProvider<SessionNotifier, String?>(SessionNotifier.new);

class SessionNotifier extends Notifier<String?> {
  @override
  String? build() {
    // Register for session invalidation from Google sign out
    GoogleAuthService.registerSessionInvalidationCallback(_onExternalSignOut);
    ref.onDispose(() {
      GoogleAuthService.removeSessionInvalidationCallback(_onExternalSignOut);
    });
    return null;
  }

  void _onExternalSignOut() {
    clearSession();
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
  }

  Future<void> logout() async {
    ref.read(sessionProvider.notifier).clearSession();
    await GoogleAuthService.signOut();
    state = null;
  }

  Future<void> updateProfile({String? name, String? emoji}) async {
    if (state == null) return;
    final updated = state!.copyWith(name: name, profileEmoji: emoji);
    await saveUser(updated);
  }

  Future<void> saveUser(UserModel user) async {
    await _storage.saveUser(user);
    state = user;
  }
}
