import 'package:supabase_flutter/supabase_flutter.dart';

/// Max ids per delete request. Keeps the URL/statement size reasonable while
/// still collapsing bulk deletes into a handful of round trips.
const kDeleteBatchSize = 300;

/// Deletes rows in [table] whose `id` is in [ids], in chunks of
/// [kDeleteBatchSize]. Each chunk is a single request (atomic per chunk).
Future<void> deleteByIds(
  SupabaseClient client,
  String table,
  List<String> ids,
) async {
  for (var i = 0; i < ids.length; i += kDeleteBatchSize) {
    final end = (i + kDeleteBatchSize) < ids.length
        ? i + kDeleteBatchSize
        : ids.length;
    final chunk = ids.sublist(i, end);
    if (chunk.isEmpty) continue;
    await client.from(table).delete().inFilter('id', chunk);
  }
}
