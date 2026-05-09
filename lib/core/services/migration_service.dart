import 'package:flutter/foundation.dart';
import 'encryption_service.dart';
import 'storage_service.dart';

/// Service to handle encryption mode switching
/// Note: Full file migration requires session key access - implemented separately
class MigrationService {
  final StorageService _storage = StorageService();

  /// Get current encryption mode
  Future<EncryptionMode> getCurrentMode() async {
    final modeStr = await _storage.getEncryptionMode();
    return modeStr == 'simple' ? EncryptionMode.simple : EncryptionMode.advanced;
  }

  /// Quick switch mode - just update storage
  /// Note: Files encrypted with old mode will still work (backward compatible)
  Future<void> quickSwitchMode(EncryptionMode mode) async {
    await _storage.setEncryptionMode(mode == EncryptionMode.simple ? 'simple' : 'advanced');
    debugPrint('Encryption mode switched to: ${mode == EncryptionMode.simple ? "simple" : "advanced"}');
  }
}

/// Track pending migrations (placeholder for future implementation)
class MigrationStatus {
  final bool isMigrating;
  final int totalFiles;
  final int migratedFiles;
  final EncryptionMode? targetMode;

  MigrationStatus({
    this.isMigrating = false,
    this.totalFiles = 0,
    this.migratedFiles = 0,
    this.targetMode,
  });

  double get progress => totalFiles > 0 ? migratedFiles / totalFiles : 0;
}