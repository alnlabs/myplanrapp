import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../shared/constants/storage_constants.dart';

class MemberAvatarRepository {
  MemberAvatarRepository(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();

  Future<String> signedUrl(String storagePath) async {
    return _client.storage
        .from(StorageBuckets.householdAvatars)
        .createSignedUrl(storagePath, 3600);
  }

  Future<String> uploadAvatar({
    required String householdId,
    required String familyMemberId,
    required Uint8List bytes,
    required String mimeType,
    String? previousPath,
  }) async {
    final ext = mimeType.contains('png')
        ? 'png'
        : mimeType.contains('webp')
            ? 'webp'
            : 'jpg';
    final storagePath = '$householdId/$familyMemberId/${_uuid.v4()}.$ext';

    await _client.storage.from(StorageBuckets.householdAvatars).uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: true),
        );

    if (previousPath != null && previousPath != storagePath) {
      try {
        await _client.storage
            .from(StorageBuckets.householdAvatars)
            .remove([previousPath]);
      } catch (_) {}
    }

    return storagePath;
  }
}

final memberAvatarRepositoryProvider = Provider<MemberAvatarRepository>((ref) {
  return MemberAvatarRepository(ref.watch(supabaseClientProvider));
});

final memberAvatarUrlProvider =
    FutureProvider.family<String?, String>((ref, storagePath) async {
  if (storagePath.isEmpty) return null;
  return ref.watch(memberAvatarRepositoryProvider).signedUrl(storagePath);
});
