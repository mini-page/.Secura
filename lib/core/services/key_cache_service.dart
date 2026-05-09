import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'encryption_service.dart';
import 'storage_service.dart';

/// In-memory key cache for fast access
/// Key is cleared when app goes to background
class KeyCacheService {
  static String? _cachedKey;
  static EncryptionMode? _cachedMode;

  /// Get cached key if available
  static String? get cachedKey => _cachedKey;

  /// Check if we have a valid cached key
  static bool get hasKey => _cachedKey != null;

  /// Cache the derived key in memory
  static void cacheKey(String key, EncryptionMode mode) {
    _cachedKey = key;
    _cachedMode = mode;
    debugPrint('Key cached in memory');
  }

  /// Clear cached key (called when app goes to background)
  static void clearCache() {
    if (_cachedKey != null) {
      debugPrint('Key cache cleared');
    }
    _cachedKey = null;
    _cachedMode = null;
  }

  /// Get cached mode
  static EncryptionMode? get cachedMode => _cachedMode;
}

/// Provider to manage key cache lifecycle
final keyCacheProvider = Provider<KeyCacheManager>((ref) => KeyCacheManager(ref));

class KeyCacheManager {
  final Ref _ref;
  bool _isListening = false;

  KeyCacheManager(this._ref) {
    _init();
  }

  void _init() {
    // This will be called when the provider is first used
    // We set up app lifecycle observer in the actual widget tree
  }

  /// Start listening to app lifecycle to clear key on background
  void startListening() {
    if (_isListening) return;
    _isListening = true;
    // Lifecycle handling is done in app_shell.dart or main.dart
  }

  /// Clear the key when app goes to background
  static void onAppPaused() {
    KeyCacheService.clearCache();
    debugPrint('App paused - key cleared from memory');
  }

  /// Derive and cache key (fast path for cached key)
  static Future<String?> getOrDeriveKey(String pin, EncryptionMode mode) async {
    // Return cached key if matches mode
    if (KeyCacheService.hasKey && KeyCacheService.cachedMode == mode) {
      debugPrint('Using cached key');
      return KeyCacheService.cachedKey;
    }

    // Derive new key
    final storage = StorageService();
    final salt = await storage.getSalt();
    if (salt == null) return null;

    final key = EncryptionService.deriveKeyWithMode(pin, salt, mode);
    KeyCacheService.cacheKey(key, mode);
    return key;
  }
}

/// Widget mixin to handle app lifecycle for key cache
mixin KeyCacheLifecycle<T extends ConsumerStatefulWidget> on ConsumerState<T>, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      KeyCacheService.clearCache();
      debugPrint('Key cleared due to app lifecycle change');
    }
  }
}