import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/storage_service.dart';

final _storage = StorageService();

final strict2FAProvider = StateNotifierProvider<Strict2FANotifier, bool>((ref) {
  return Strict2FANotifier();
});

class Strict2FANotifier extends StateNotifier<bool> {
  Strict2FANotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    state = await _storage.getStrict2FA();
  }

  Future<void> toggle(bool value) async {
    await _storage.setStrict2FA(value);
    state = value;
  }
}

final autoLockProvider = StateNotifierProvider<AutoLockNotifier, bool>((ref) {
  return AutoLockNotifier();
});

class AutoLockNotifier extends StateNotifier<bool> {
  AutoLockNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    state = await _storage.getAutoLock();
  }

  Future<void> toggle(bool value) async {
    await _storage.setAutoLock(value);
    state = value;
  }
}
