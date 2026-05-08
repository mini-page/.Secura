import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/storage_service.dart';

final _storage = StorageService();

final strict2FAProvider = NotifierProvider<Strict2FANotifier, bool>(Strict2FANotifier.new);

class Strict2FANotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    state = await _storage.getStrict2FA();
  }

  Future<void> toggle(bool value) async {
    await _storage.setStrict2FA(value);
    state = value;
  }
}

final autoLockProvider = NotifierProvider<AutoLockNotifier, bool>(AutoLockNotifier.new);

class AutoLockNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    state = await _storage.getAutoLock();
  }

  Future<void> toggle(bool value) async {
    await _storage.setAutoLock(value);
    state = value;
  }
}
