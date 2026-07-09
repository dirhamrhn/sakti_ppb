import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';

class SupabaseStorageService {
  SupabaseStorageService._();

  static final SupabaseStorageService instance =
      SupabaseStorageService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Upload File
  Future<String> uploadFile({
    required File file,
    required String path,
  }) async {
    // Proactively try to create the bucket if it doesn't exist
    try {
      await _client.storage.createBucket(
        SupabaseConfig.bucket,
        const BucketOptions(
          public: true,
        ),
      );
    } catch (_) {
      // Ignore error if bucket already exists or no permission
    }

    await _client.storage
        .from(SupabaseConfig.bucket)
        .upload(
          path,
          file,
          fileOptions: const FileOptions(
            upsert: true,
          ),
        );

    return getPublicUrl(path);
  }

  /// Public URL
  String getPublicUrl(String path) {
    return _client.storage
        .from(SupabaseConfig.bucket)
        .getPublicUrl(path);
  }

  /// Delete File
  Future<void> deleteFile(
    String path,
  ) async {
    await _client.storage
        .from(SupabaseConfig.bucket)
        .remove([path]);
  }
}
