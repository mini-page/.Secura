import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/file_vault_service.dart';
import 'vault_file_model.dart';

final fileVaultServiceProvider = Provider((ref) => FileVaultService(ref));

// Provider to track last error for UI feedback
final lastErrorProvider = NotifierProvider<LastErrorNotifier, String?>(LastErrorNotifier.new);

class LastErrorNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setError(String? error) {
    state = error;
  }

  void clear() {
    state = null;
  }
}

// Provider for operation status
enum VaultOperationStatus { idle, loading, success, error }

final vaultOperationStatusProvider = NotifierProvider<VaultStatusNotifier, VaultOperationStatus>(VaultStatusNotifier.new);

class VaultStatusNotifier extends Notifier<VaultOperationStatus> {
  @override
  VaultOperationStatus build() => VaultOperationStatus.idle;

  void setStatus(VaultOperationStatus status) {
    state = status;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

final filteredVaultProvider = Provider<AsyncValue<List<VaultFile>>>((ref) {
  final vaultState = ref.watch(vaultProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  return vaultState.whenData((files) {
    if (query.isEmpty) return files;
    return files.where((file) {
      final name = file.isEncrypted
          ? file.name.replaceAll('.secura', '').toLowerCase()
          : file.name.toLowerCase();
      return name.contains(query);
    }).toList();
  });
});

final vaultProvider = AsyncNotifierProvider<VaultNotifier, List<VaultFile>>(VaultNotifier.new);

class VaultNotifier extends AsyncNotifier<List<VaultFile>> {
  late final FileVaultService _service;

  @override
  Future<List<VaultFile>> build() async {
    _service = ref.watch(fileVaultServiceProvider);
    return _service.listFiles();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final files = await _service.listFiles();
      state = AsyncValue.data(files);
      ref.read(lastErrorProvider.notifier).state = null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      ref.read(lastErrorProvider.notifier).state = e.toString();
    }
  }

  Future<bool> addFile(File source, {required bool encrypt}) async {
    ref.read(vaultOperationStatusProvider.notifier).state = VaultOperationStatus.loading;
    try {
      await _service.addFile(source, encrypt: encrypt);
      await refresh();
      ref.read(vaultOperationStatusProvider.notifier).state = VaultOperationStatus.success;
      return true;
    } on VaultException catch (e) {
      ref.read(lastErrorProvider.notifier).state = e.displayMessage;
      ref.read(vaultOperationStatusProvider.notifier).state = VaultOperationStatus.error;
      return false;
    } catch (e) {
      ref.read(lastErrorProvider.notifier).state = 'Failed to add file';
      ref.read(vaultOperationStatusProvider.notifier).state = VaultOperationStatus.error;
      return false;
    }
  }

  Future<bool> deleteFile(VaultFile file) async {
    ref.read(vaultOperationStatusProvider.notifier).state = VaultOperationStatus.loading;
    try {
      await _service.deleteFile(file);
      await refresh();
      ref.read(vaultOperationStatusProvider.notifier).state = VaultOperationStatus.success;
      return true;
    } on VaultException catch (e) {
      ref.read(lastErrorProvider.notifier).state = e.displayMessage;
      ref.read(vaultOperationStatusProvider.notifier).state = VaultOperationStatus.error;
      return false;
    } catch (e) {
      ref.read(lastErrorProvider.notifier).state = 'Failed to delete file';
      ref.read(vaultOperationStatusProvider.notifier).state = VaultOperationStatus.error;
      return false;
    }
  }

  Future<bool> encryptExistingFile(VaultFile file) async {
    ref.read(vaultOperationStatusProvider.notifier).state = VaultOperationStatus.loading;
    try {
      await _service.encryptFile(file);
      await refresh();
      ref.read(vaultOperationStatusProvider.notifier).state = VaultOperationStatus.success;
      return true;
    } on VaultException catch (e) {
      ref.read(lastErrorProvider.notifier).state = e.displayMessage;
      ref.read(vaultOperationStatusProvider.notifier).state = VaultOperationStatus.error;
      return false;
    } catch (e) {
      ref.read(lastErrorProvider.notifier).state = 'Failed to encrypt file';
      ref.read(vaultOperationStatusProvider.notifier).state = VaultOperationStatus.error;
      return false;
    }
  }
}

final recycleBinProvider = AsyncNotifierProvider<RecycleBinNotifier, List<VaultFile>>(RecycleBinNotifier.new);

class RecycleBinNotifier extends AsyncNotifier<List<VaultFile>> {
  late final FileVaultService _service;
  late final Ref _ref;

  @override
  Future<List<VaultFile>> build() async {
    _service = ref.watch(fileVaultServiceProvider);
    _ref = ref;
    return _service.listRecycleBin();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final files = await _service.listRecycleBin();
      state = AsyncValue.data(files);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> restoreFile(VaultFile file) async {
    try {
      await _service.restoreFromRecycleBin(file);
      await refresh();
      _ref.read(vaultProvider.notifier).refresh();
      return true;
    } on VaultException catch (e) {
      ref.read(lastErrorProvider.notifier).state = e.displayMessage;
      return false;
    } catch (e) {
      ref.read(lastErrorProvider.notifier).state = 'Failed to restore file';
      return false;
    }
  }

  Future<bool> permanentlyDelete(VaultFile file) async {
    try {
      await _service.permanentlyDeleteFile(file);
      await refresh();
      return true;
    } on VaultException catch (e) {
      ref.read(lastErrorProvider.notifier).state = e.displayMessage;
      return false;
    } catch (e) {
      ref.read(lastErrorProvider.notifier).state = 'Failed to delete file';
      return false;
    }
  }

  Future<bool> emptyBin() async {
    try {
      await _service.emptyRecycleBin();
      await refresh();
      return true;
    } on VaultException catch (e) {
      ref.read(lastErrorProvider.notifier).state = e.displayMessage;
      return false;
    } catch (e) {
      ref.read(lastErrorProvider.notifier).state = 'Failed to empty recycle bin';
      return false;
    }
  }
}
