import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../../shared/constants/list_pagination.dart';
import '../../../shared/constants/storage_constants.dart';
import '../../../shared/utils/batch_delete.dart';
import '../../auth/data/auth_repository.dart';
import 'models/receipt_analysis.dart';
import 'models/saved_receipt.dart';

class AssistantRepository {
  AssistantRepository(this._client);

  final SupabaseClient _client;
  final _uuid = const Uuid();

  /// Sends the receipt image to the `assistant` edge function for vision
  /// extraction + feature mapping. Computes the dedup fingerprint on-device.
  Future<ReceiptAnalysis> analyzeReceipt({
    required Uint8List bytes,
    required String mimeType,
    bool force = false,
  }) async {
    final fingerprint = sha256.convert(bytes).toString();
    debugPrint('[assistant] analyzeReceipt start '
        'bytes=${bytes.length} mime=$mimeType force=$force fp=$fingerprint');
    try {
      final response = await _client.functions.invoke(
        'assistant',
        body: {
          'imageBase64': base64Encode(bytes),
          'fingerprint': fingerprint,
          'mimeType': mimeType,
          'force': force,
        },
      );
      final data = response.data;
      debugPrint('[assistant] analyzeReceipt ok status=${response.status}');
      if (data is! Map) throw Exception('Receipt analysis failed');
      return ReceiptAnalysis.fromJson(Map<String, dynamic>.from(data));
    } on FunctionException catch (e, st) {
      // functions.invoke throws on any non-2xx; the edge function's friendly
      // `message` (quota/config/etc.) lives in `details`.
      debugPrint('[assistant] analyzeReceipt FunctionException '
          'status=${e.status} reason=${e.reasonPhrase} details=${e.details}');
      AppLogger.instance.error(
        'assistant.analyzeReceipt failed (status ${e.status})',
        'reason=${e.reasonPhrase} details=${e.details}',
        st,
      );
      throw Exception(_messageFromDetails(e.details) ?? 'Receipt analysis failed');
    } catch (e, st) {
      debugPrint('[assistant] analyzeReceipt error: $e');
      AppLogger.instance.error('assistant.analyzeReceipt error', e, st);
      rethrow;
    }
  }

  String? _messageFromDetails(dynamic details) {
    Map<String, dynamic>? map;
    if (details is Map) {
      map = Map<String, dynamic>.from(details);
    } else if (details is String && details.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(details);
        if (decoded is Map) map = Map<String, dynamic>.from(decoded);
      } catch (_) {
        return details;
      }
    }
    if (map == null) return null;
    return (map['message'] ?? map['error'])?.toString();
  }

  /// Bring-your-own-AI path: the user runs our prompt in any external AI app and
  /// pastes back JSON. We parse it locally (no model call, no cost), assign
  /// stable line indices, derive a soft dedup fingerprint, and match lines
  /// against the existing pantry so restocks aren't duplicated.
  Future<ReceiptAnalysis> analyzePasted({
    required String jsonText,
    required String householdId,
  }) async {
    dynamic decoded;
    try {
      decoded = jsonDecode(_extractJson(jsonText));
    } catch (_) {
      throw Exception('That is not valid JSON. Paste the AI output exactly.');
    }
    if (decoded is! Map) {
      throw Exception('Expected a JSON object with an "items" list.');
    }

    final parsed = ReceiptAnalysis.fromJson(Map<String, dynamic>.from(decoded));

    // External output has no stable indices; assign them so per-line apply and
    // "mark applied" target the right row.
    final indexed = <ReceiptLine>[
      for (var i = 0; i < parsed.lines.length; i++)
        parsed.lines[i].copyWith(lineIndex: i),
    ];

    final matched = await _matchPantry(householdId, indexed);
    final fingerprint = parsed.fingerprint.isNotEmpty
        ? parsed.fingerprint
        : _softFingerprint(parsed, matched);

    // Same dedup guard as the scan path: warn if this receipt was already
    // processed for the household.
    final existing = await _client
        .from('receipts')
        .select('id, status')
        .eq('household_id', householdId)
        .eq('fingerprint', fingerprint)
        .maybeSingle();

    return ReceiptAnalysis(
      fingerprint: fingerprint,
      merchant: parsed.merchant,
      purchasedAt: parsed.purchasedAt,
      total: parsed.total,
      currency: parsed.currency ?? 'INR',
      suggestedCategoryId: parsed.suggestedCategoryId,
      suggestedCategoryName: parsed.suggestedCategoryName,
      alreadyProcessed: existing != null && existing['status'] == 'processed',
      existingReceiptId: existing?['id'] as String?,
      lines: matched,
    );
  }

  /// Tolerates AI apps that wrap JSON in ```json fences or prose by grabbing the
  /// outermost object.
  String _extractJson(String raw) {
    final trimmed = raw.trim();
    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return trimmed;
    return trimmed.substring(start, end + 1);
  }

  String _softFingerprint(ReceiptAnalysis a, List<ReceiptLine> lines) {
    final buffer = StringBuffer()
      ..write((a.merchant ?? '').toLowerCase().trim())
      ..write('|')
      ..write(a.purchasedAt?.toIso8601String().split('T').first ?? '')
      ..write('|')
      ..write(a.total?.toStringAsFixed(2) ?? '')
      ..write('|');
    for (final line in lines) {
      buffer
        ..write(line.name.toLowerCase().trim())
        ..write('#')
        ..write(line.qty ?? '')
        ..write(';');
    }
    return 'manual:${sha256.convert(utf8.encode(buffer.toString()))}';
  }

  Future<List<ReceiptLine>> _matchPantry(
    String householdId,
    List<ReceiptLine> lines,
  ) async {
    final needsMatch = lines.any((l) =>
        l.destination == ReceiptLineDestination.pantry &&
        l.matchedItemId == null);
    if (!needsMatch) return lines;

    final rows = await _client
        .from('pantry_items')
        .select('id, name')
        .eq('household_id', householdId)
        .limit(kSafetyFetchCap);
    final items = (rows as List).cast<Map<String, dynamic>>();
    String norm(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final byName = <String, Map<String, dynamic>>{
      for (final it in items)
        norm((it['name'] as String?) ?? ''): it,
    };

    return [
      for (final line in lines)
        if (line.destination == ReceiptLineDestination.pantry &&
            line.matchedItemId == null &&
            byName.containsKey(norm(line.name)))
          line.copyWith(
            matchedItemId: byName[norm(line.name)]!['id'] as String,
            matchedItemName: byName[norm(line.name)]!['name'] as String,
          )
        else
          line,
    ];
  }

  /// Persists the receipt (once) with its image and detected line items. Returns
  /// the receipt id. Idempotent per (household, fingerprint): if a row already
  /// exists it is reused rather than duplicated.
  Future<String> persistReceipt({
    required String householdId,
    required ReceiptAnalysis analysis,
    required List<ReceiptLine> lines,
    Uint8List? imageBytes,
    String? mimeType,
  }) async {
    final existing = await _client
        .from('receipts')
        .select('id')
        .eq('household_id', householdId)
        .eq('fingerprint', analysis.fingerprint)
        .maybeSingle();
    if (existing != null) return existing['id'] as String;

    // Manual (paste) receipts have no image; only upload when one is provided.
    String? imagePath;
    if (imageBytes != null) {
      imagePath = '$householdId/receipts/${_uuid.v4()}.jpg';
      await _client.storage
          .from(StorageBuckets.householdAttachments)
          .uploadBinary(
            imagePath,
            imageBytes,
            fileOptions: FileOptions(
              contentType: mimeType ?? 'image/jpeg',
              upsert: true,
            ),
          );
    }

    final receipt = await _client
        .from('receipts')
        .insert({
          'household_id': householdId,
          'created_by': _client.auth.currentUser?.id,
          'fingerprint': analysis.fingerprint,
          'merchant': analysis.merchant,
          'purchased_at': analysis.purchasedAt?.toIso8601String().split('T').first,
          'total': analysis.total,
          'currency': analysis.currency,
          'image_path': imagePath,
          'status': 'pending',
        })
        .select('id')
        .single();
    final receiptId = receipt['id'] as String;

    if (lines.isNotEmpty) {
      await _client.from('receipt_line_items').insert([
        for (final line in lines)
          {
            'receipt_id': receiptId,
            'line_index': line.lineIndex,
            'raw_text': line.rawText,
            'name': line.name,
            'qty': line.qty,
            'unit': line.unit,
            'destination': line.destination.dbValue,
            'action': line.isRestock ? 'restock' : 'create',
            'matched_item_id': line.matchedItemId,
          },
      ]);
    }

    return receiptId;
  }

  Future<void> markLineApplied({
    required String receiptId,
    required int lineIndex,
    String? appliedRef,
  }) async {
    await _client
        .from('receipt_line_items')
        .update({
          'applied_at': DateTime.now().toUtc().toIso8601String(),
          'applied_ref': appliedRef,
        })
        .eq('receipt_id', receiptId)
        .eq('line_index', lineIndex);
  }

  Future<void> markReceiptProcessed(String receiptId) async {
    await _client
        .from('receipts')
        .update({'status': 'processed'}).eq('id', receiptId);
  }

  /// Most-recent-first list of saved receipts for the household, with a line
  /// item count for each.
  Future<List<SavedReceipt>> fetchReceipts(String householdId) async {
    final data = await _client
        .from('receipts')
        .select(
          'id, status, merchant, purchased_at, total, currency, created_at, '
          'receipt_line_items(count)',
        )
        .eq('household_id', householdId)
        .order('created_at', ascending: false)
        .limit(kSafetyFetchCap);
    return (data as List)
        .cast<Map<String, dynamic>>()
        .map(SavedReceipt.fromJson)
        .toList();
  }

  /// Deletes a receipt and its line items (cascade handles the children).
  Future<void> deleteReceipt(String receiptId) async {
    await _client.from('receipts').delete().eq('id', receiptId);
  }

  Future<void> deleteReceipts(List<String> ids) async {
    await deleteByIds(_client, 'receipts', ids);
  }

  /// Line items for one receipt, ordered as printed.
  Future<List<Map<String, dynamic>>> fetchReceiptLines(String receiptId) async {
    final data = await _client
        .from('receipt_line_items')
        .select()
        .eq('receipt_id', receiptId)
        .order('line_index')
        .limit(kSafetyFetchCap);
    return (data as List).cast<Map<String, dynamic>>();
  }
}

/// Household-scoped list of saved receipts. Auto-disposes so it reloads on open.
final savedReceiptsProvider =
    FutureProvider.autoDispose<List<SavedReceipt>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return const [];
  return ref.watch(assistantRepositoryProvider).fetchReceipts(householdId);
});

final assistantRepositoryProvider = Provider<AssistantRepository>((ref) {
  return AssistantRepository(ref.watch(supabaseClientProvider));
});
