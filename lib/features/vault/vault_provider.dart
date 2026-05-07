import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/file_vault_service.dart';
import 'vault_file_model.dart';

final fileVaultServiceProvider = Provider((ref) => FileVaultService(ref));

final searchQueryProvider = StateProvider<String>((ref) => '');

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

final vaultProvider = StateNotifierProvider<VaultNotifier, AsyncValue<List<VaultFile>>>((ref) {
  final service = ref.watch(fileVaultServiceProvider);
  return VaultNotifier(service);
});

final recycleBinProvider = StateNotifierProvider<RecycleBinNotifier, AsyncValue<List<VaultFile>>>((ref) {
  final service = ref.watch(fileVaultServiceProvider);
  return RecycleBinNotifier(service, ref);
});

class VaultNotifier extends StateNotifier<AsyncValue<List<VaultFile>>> {
  final FileVaultService _service;

  VaultNotifier(this._service) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final files = await _service.listFiles();
      state = AsyncValue.data(files);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
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

class RecycleBinNotifier extends StateNotifier<AsyncValue<List<VaultFile>>> {
  final FileVaultService _service;
  final Ref _ref;

  RecycleBinNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final files = await _service.listRecycleBin();
      state = AsyncValue.data(files);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
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
