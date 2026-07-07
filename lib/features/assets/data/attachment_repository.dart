import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../shared/constants/storage_constants.dart';
import '../../../shared/models/asset_attachment.dart';

class AttachmentRepository {
  AttachmentRepository(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();

  Future<List<AssetAttachment>> fetchAttachments(String assetId) async {
    final data = await _client
        .from('asset_attachments')
        .select()
        .eq('asset_id', assetId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => AssetAttachment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> signedUrl(String storagePath) async {
    return _client.storage
        .from(StorageBuckets.householdAttachments)
        .createSignedUrl(storagePath, 3600);
  }

  Future<AssetAttachment> uploadAttachment({
    required String householdId,
    required String assetId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    String attachmentType = AttachmentTypes.warranty,
  }) async {
    final userId = _client.auth.currentUser?.id;
    final safeName = fileName.replaceAll(RegExp(r'[^\w.\-]+'), '_');
    final storagePath =
        '$householdId/$assetId/${_uuid.v4()}_$safeName';

    await _client.storage.from(StorageBuckets.householdAttachments).uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );

    final data = await _client
        .from('asset_attachments')
        .insert({
          'asset_id': assetId,
          'household_id': householdId,
          'created_by': userId,
          'attachment_type': attachmentType,
          'storage_path': storagePath,
          'file_name': safeName,
          'mime_type': mimeType,
          'file_size_bytes': bytes.length,
        })
        .select()
        .single();

    return AssetAttachment.fromJson(data);
  }

  Future<void> deleteAttachment(AssetAttachment attachment) async {
    await _client.storage
        .from(StorageBuckets.householdAttachments)
        .remove([attachment.storagePath]);
    await _client.from('asset_attachments').delete().eq('id', attachment.id);
  }
}

final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  return AttachmentRepository(ref.watch(supabaseClientProvider));
});

final assetAttachmentsProvider =
    FutureProvider.family<List<AssetAttachment>, String>((ref, assetId) async {
  return ref.watch(attachmentRepositoryProvider).fetchAttachments(assetId);
});

final attachmentSignedUrlProvider =
    FutureProvider.family<String, String>((ref, storagePath) async {
  return ref.watch(attachmentRepositoryProvider).signedUrl(storagePath);
});
