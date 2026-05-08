import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/auth/user_model.dart';

class StorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _authHashKey = 'user_auth_hash';
  static const _saltKey = 'user_salt';
  static const _userKey = 'user_profile_';
  static const _themeKey = 'app_theme_mode';
  static const _strict2faKey = 'strict_2fa_mode';
  static const _autoLockKey = 'auto_lock_timeout';

  // Generic Secure Data Methods
  Future<void> saveSecureData(String key, String value) async {
    try {
      await _storage.write(key: key, value: value).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Storage Error (Save): $e');
    }
  }

  Future<String?> getSecureData(String key) async {
    try {
      return await _storage.read(key: key).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Storage Error (Read): $e');
      return null;
    }
  }

  Future<void> deleteSecureData(String key) async {
    try {
      await _storage.delete(key: key).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Storage Error (Delete): $e');
    }
  }

  Future<void> saveAuthHash(String hash) async {
    await saveSecureData(_authHashKey, hash);
  }

  Future<String?> getAuthHash() async {
    return await getSecureData(_authHashKey);
  }

  Future<void> saveSalt(String salt) async {
    await saveSecureData(_saltKey, salt);
  }

  Future<String?> getSalt() async {
    return await getSecureData(_saltKey);
  }

  Future<void> setStrict2FA(bool value) async {
    await saveSecureData(_strict2faKey, value.toString());
  }

  Future<bool> getStrict2FA() async {
    final value = await getSecureData(_strict2faKey);
    return value == 'true';
  }

  Future<void> setAutoLock(bool value) async {
    await saveSecureData(_autoLockKey, value.toString());
  }

  Future<bool> getAutoLock() async {
    final value = await getSecureData(_autoLockKey);
    return value == 'true';
  }

  Future<void> saveUser(UserModel user) async {
    final jsonStr = jsonEncode(user.toJson());
    await saveSecureData('$_userKey${user.email}', jsonStr);
    await saveSecureData('last_logged_in_email', user.email);
  }

  Future<UserModel?> getUser(String email) async {
    final data = await getSecureData('$_userKey$email');
    if (data == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(data));
    } catch (e) {
      return null;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final email = await getSecureData('last_logged_in_email');
    if (email == null) return null;
    return getUser(email);
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    await saveSecureData(_themeKey, mode.name);
  }

  Future<ThemeMode> getThemeMode() async {
    final value = await getSecureData(_themeKey);
    return ThemeMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ThemeMode.light,
    );
  }

  Future<Map<String, dynamic>> getAllSettings() async {
    return {
      'themeMode': (await getThemeMode()).name,
      'strict2fa': await getStrict2FA(),
      'autoLock': await getAutoLock(),
      'salt': await getSalt(),
      'authHash': await getAuthHash(),
    };
  }

  Future<void> restoreSettings(Map<String, dynamic> settings) async {
    if (settings.containsKey('themeMode')) {
      final mode = ThemeMode.values.firstWhere((e) => e.name == settings['themeMode'], orElse: () => ThemeMode.light);
      await saveThemeMode(mode);
    }
    if (settings.containsKey('strict2fa')) {
      await setStrict2FA(settings['strict2fa'] as bool);
    }
    if (settings.containsKey('autoLock')) {
      await setAutoLock(settings['autoLock'] as bool);
    }
    if (settings.containsKey('salt')) {
      await saveSalt(settings['salt'] as String);
    }
    if (settings.containsKey('authHash')) {
      await saveAuthHash(settings['authHash'] as String);
    }
  }

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll().timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Storage Error (Clear): $e');
    }
  }
}
