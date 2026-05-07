import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/storage_service.dart';
import '../auth/user_model.dart';

final sessionProvider = StateProvider<String?>((ref) => null);

final userProvider = StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<UserModel?> {
  UserNotifier() : super(null) {
    loadUser();
  }

  final _storage = StorageService();

  Future<void> loadUser() async {
    state = await _storage.getCurrentUser();
  }

  Future<void> login(String phone) async {
    final existing = await _storage.getUser(phone);
    if (existing != null) {
      state = existing;
      await _storage.saveUser(existing);
    } else {
      final newUser = UserModel(phoneNumber: phone, name: 'New User');
      await _storage.saveUser(newUser);
      state = newUser;
    }
  }

  Future<void> updateProfile({String? name, String? emoji}) async {
    if (state == null) return;
    final updated = state!.copyWith(name: name, profileEmoji: emoji);
    await _storage.saveUser(updated);
    state = updated;
  }
}
