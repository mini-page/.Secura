import 'dart:io';
import 'package:flutter/foundation.dart';
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

enum VaultSort { newest, oldest, nameAZ, nameZA, largest, smallest }

final vaultFilterProvider = NotifierProvider<VaultFilterNotifier, VaultFilter>(VaultFilterNotifier.new);
final vaultSortProvider = NotifierProvider<VaultSortNotifier, VaultSort>(VaultSortNotifier.new);

class VaultFilterNotifier extends Notifier<VaultFilter> {
  @override
  VaultFilter build() => VaultFilter.all;

  void setFilter(VaultFilter filter) {
    state = filter;
  }
}

class VaultSortNotifier extends Notifier<VaultSort> {
  @override
  VaultSort build() => VaultSort.newest;

  void setSort(VaultSort sort) {
    state = sort;
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
  final sort = ref.watch(vaultSortProvider);

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

    // Apply sorting
    switch (sort) {
      case VaultSort.newest:
        filtered.sort((a, b) => b.modified.compareTo(a.modified));
        break;
      case VaultSort.oldest:
        filtered.sort((a, b) => a.modified.compareTo(b.modified));
        break;
      case VaultSort.nameAZ:
        filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case VaultSort.nameZA:
        filtered.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case VaultSort.largest:
        filtered.sort((a, b) => b.size.compareTo(a.size));
        break;
      case VaultSort.smallest:
        filtered.sort((a, b) => a.size.compareTo(b.size));
        break;
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
    try {
      return await service.listFiles();
    } catch (e) {
      // Return empty list if storage is unavailable (web/emulator hot reload)
      return [];
    }
  }

  Future<void> refresh() async {
    try {
      final files = await service.listFiles();
      debugPrint('Refreshing vault: ${files.length} files found');
      state = AsyncValue.data(files);
      ref.read(lastErrorProvider.notifier).state = null;
    } catch (e, st) {
      debugPrint('Error refreshing vault: $e');
      state = AsyncValue.error(e, st);
      ref.read(lastErrorProvider.notifier).state = e.toString();
    }
  }

  Future<bool> addFile(File source, {required bool encrypt}) async {
    ref.read(vaultOperationStatusProvider.notifier).state = VaultOperationStatus.loading;
    try {
      await service.addFile(source, encrypt: encrypt);
      
      // CRITICAL: Ensure we refresh the state after adding
      final files = await service.listFiles();
      state = AsyncValue.data(files);
      
      ref.read(vaultOperationStatusProvider.notifier).state = VaultOperationStatus.success;
      return true;
    } on VaultException catch (e) {
      debugPrint('VaultException adding file: ${e.message}');
      ref.read(lastErrorProvider.notifier).state = e.displayMessage;
      ref.read(vaultOperationStatusProvider.notifier).state = VaultOperationStatus.error;
      return false;
    } catch (e, st) {
      debugPrint('Error adding file: $e\n$st');
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

  Future<bool> decryptExistingFile(VaultFile file) async {
    ref.read(vaultOperationStatusProvider.notifier).state = VaultOperationStatus.loading;
    try {
      await service.decryptFile(file);
      await refresh();
      ref.read(vaultOperationStatusProvider.notifier).state = VaultOperationStatus.success;
      return true;
    } on VaultException catch (e) {
      ref.read(lastErrorProvider.notifier).state = e.displayMessage;
      ref.read(vaultOperationStatusProvider.notifier).state = VaultOperationStatus.error;
      return false;
    } catch (e) {
      ref.read(lastErrorProvider.notifier).state = 'Failed to decrypt file';
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

  Future<int> batchDecrypt(List<VaultFile> files) async {
    int successCount = 0;
    for (final file in files) {
      if (file.isEncrypted) {
        if (await decryptExistingFile(file)) {
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
