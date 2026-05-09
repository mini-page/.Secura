import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/encryption_service.dart';
import 'package:local_auth/local_auth.dart';

final _storage = StorageService();
final _localAuth = LocalAuthentication();

final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  final canAuth = await _localAuth.canCheckBiometrics;
  final isDeviceSupported = await _localAuth.isDeviceSupported();
  return canAuth && isDeviceSupported;
});

final biometricEnabledProvider = NotifierProvider<BiometricEnabledNotifier, bool>(BiometricEnabledNotifier.new);

class BiometricEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    state = await _storage.getBiometricEnabled();
  }

  Future<void> toggle(bool value) async {
    await _storage.setBiometricEnabled(value);
    state = value;
  }
}

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

// Encryption mode provider (simple/fast vs advanced/secure)
final encryptionModeProvider = NotifierProvider<EncryptionModeNotifier, EncryptionMode>(EncryptionModeNotifier.new);

class EncryptionModeNotifier extends Notifier<EncryptionMode> {
  @override
  EncryptionMode build() {
    _load();
    return EncryptionMode.advanced;
  }

  Future<void> _load() async {
    final mode = await _storage.getEncryptionMode();
    state = mode == 'simple' ? EncryptionMode.simple : EncryptionMode.advanced;
  }

  Future<void> setMode(EncryptionMode mode) async {
    await _storage.setEncryptionMode(mode == EncryptionMode.simple ? 'simple' : 'advanced');
    state = mode;
  }

  int get iterations => state == EncryptionMode.simple
      ? KeyDerivationConfig.simpleIterations
      : KeyDerivationConfig.advancedIterations;
}
