import 'dart:io';

import '../services/storage/supabase_storage_service.dart';

class StorageRepository {
  StorageRepository._();

  static final StorageRepository instance =
      StorageRepository._();

  final _service =
      SupabaseStorageService.instance;

  Future<String> uploadFile({
    required File file,
    required String path,
  }) async {
    return await _service.uploadFile(
      file: file,
      path: path,
    );
  }

  Future<void> deleteFile(
    String path,
  ) async {
    await _service.deleteFile(path);
  }
}
