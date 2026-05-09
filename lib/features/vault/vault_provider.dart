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

enum VaultFilter { all, encrypted, decrypted }

final vaultFilterProvider = NotifierProvider<VaultFilterNotifier, VaultFilter>(VaultFilterNotifier.new);

class VaultFilterNotifier extends Notifier<VaultFilter> {
  @override
  VaultFilter build() => VaultFilter.all;

  void setFilter(VaultFilter filter) {
    state = filter;
  }
}

// Batch selection state
final batchModeProvider = NotifierProvider<BatchModeNotifier, bool>(BatchModeNotifier.new);

class BatchModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void enable() => state = true;
  void disable() => state = false;
}

final selectedFilesProvider = NotifierProvider<SelectedFilesNotifier, Set<String>>(SelectedFilesNotifier.new);

class SelectedFilesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggle(String path) {
    if (state.contains(path)) {
      state = {...state}..remove(path);
    } else {
      state = {...state, path};
    }
  }

  void selectAll(List<String> paths) {
    state = {...paths};
  }

  void clear() => state = {};
  int get count => state.length;
}

final filteredVaultProvider = Provider<AsyncValue<List<VaultFile>>>((ref) {
  final vaultState = ref.watch(vaultProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final filter = ref.watch(vaultFilterProvider);

  return vaultState.whenData((files) {
    var filtered = files;

    // Apply search
    if (query.isNotEmpty) {
      filtered = filtered.where((file) {
        final name = file.isEncrypted
            ? file.name.replaceAll('.secura', '').toLowerCase()
            : file.name.toLowerCase();
        return name.contains(query);
      }).toList();
    }

    // Apply filter
    if (filter == VaultFilter.encrypted) {
      filtered = filtered.where((file) => file.isEncrypted).toList();
    } else if (filter == VaultFilter.decrypted) {
      filtered = filtered.where((file) => !file.isEncrypted).toList();
    }

    return filtered;
  });
});

final vaultProvider = AsyncNotifierProvider<VaultNotifier, List<VaultFile>>(VaultNotifier.new);

class VaultNotifier extends AsyncNotifier<List<VaultFile>> {
  FileVaultService? _service;

  FileVaultService get service {
    if (_service == null) {
      _service = ref.read(fileVaultServiceProvider);
    }
    return _service!;
  }

  @override
  Future<List<VaultFile>> build() async {
    return service.listFiles();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final files = await service.listFiles();
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
      await service.addFile(source, encrypt: encrypt);
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
      await service.deleteFile(file);
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
      await service.encryptFile(file);
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

  Future<int> batchEncrypt(List<VaultFile> files) async {
    int successCount = 0;
    for (final file in files) {
      if (!file.isEncrypted) {
        if (await encryptExistingFile(file)) {
          successCount++;
        }
      }
    }
    return successCount;
  }

  Future<int> batchDelete(List<VaultFile> files) async {
    int successCount = 0;
    for (final file in files) {
      if (await deleteFile(file)) {
        successCount++;
      }
    }
    return successCount;
  }
}

final recycleBinProvider = AsyncNotifierProvider<RecycleBinNotifier, List<VaultFile>>(RecycleBinNotifier.new);

class RecycleBinNotifier extends AsyncNotifier<List<VaultFile>> {
  FileVaultService? _service;

  FileVaultService get service {
    if (_service == null) {
      _service = ref.read(fileVaultServiceProvider);
    }
    return _service!;
  }

  @override
  Future<List<VaultFile>> build() async {
    return service.listRecycleBin();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final files = await service.listRecycleBin();
      state = AsyncValue.data(files);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> restoreFile(VaultFile file) async {
    try {
      await service.restoreFromRecycleBin(file);
      await refresh();
      ref.read(vaultProvider.notifier).refresh();
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
      await service.permanentlyDeleteFile(file);
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
      await service.emptyRecycleBin();
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
