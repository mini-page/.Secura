import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/file_vault_service.dart';
import 'vault_file_model.dart';

final fileVaultServiceProvider = Provider((ref) => FileVaultService(ref));

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
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addFile(File source, {required bool encrypt}) async {
    try {
      await _service.addFile(source, encrypt: encrypt);
      await refresh();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteFile(VaultFile file) async {
    try {
      await _service.deleteFile(file);
      await refresh();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> encryptExistingFile(VaultFile file) async {
    try {
      await _service.encryptFile(file);
      await refresh();
    } catch (e) {
      // Handle error
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

  Future<void> restoreFile(VaultFile file) async {
    try {
      await _service.restoreFromRecycleBin(file);
      await refresh();
      _ref.read(vaultProvider.notifier).refresh();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> permanentlyDelete(VaultFile file) async {
    try {
      await _service.permanentlyDeleteFile(file);
      await refresh();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> emptyBin() async {
    try {
      await _service.emptyRecycleBin();
      await refresh();
    } catch (e) {
      // Handle error
    }
  }
}
