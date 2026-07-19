import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/providers/supabase_providers.dart';

/// A single resettable data feature (module). [key] must match the values the
/// `reset_household_data` RPC understands.
class ResetFeature {
  const ResetFeature(this.key, this.label, this.description);

  final String key;
  final String label;
  final String description;

  /// All transactional features that a "Reset all" clears. Excludes login
  /// accounts, memberships, the family roster, and household settings.
  static const all = <ResetFeature>[
    ResetFeature('money', 'Expenses & income',
        'All expenses, income, and recurring money rules'),
    ResetFeature('pantry', 'Pantry', 'All pantry items and stock history'),
    ResetFeature('shopping', 'Shopping list', 'All shopping list items'),
    ResetFeature('assets', 'Assets', 'All home assets and service records'),
    ResetFeature('subscriptions', 'Subscriptions', 'All tracked subscriptions'),
    ResetFeature('reminders', 'Reminders', 'All standalone reminders'),
    ResetFeature('plans', 'Plans', 'All plans and meal plans'),
    ResetFeature('recipes', 'Recipes', 'All saved recipes'),
    ResetFeature('receipts', 'Scanned receipts', 'All scanned/pasted receipts'),
  ];
}

class DataResetRepository {
  DataResetRepository(this._client);

  final SupabaseClient _client;

  /// Clears the given [features] for [householdId]. Returns a map of
  /// {featureKey: rowsDeleted}. Owner-only (enforced server-side).
  Future<Map<String, int>> resetData(
    String householdId,
    List<String> features,
  ) async {
    AppLogger.instance.info('Reset household data: $features');
    try {
      final res = await _client.rpc<dynamic>(
        'reset_household_data',
        params: {
          'p_household_id': householdId,
          'p_features': features,
        },
      );
      final counts = <String, int>{};
      if (res is Map) {
        res.forEach((key, value) {
          counts[key.toString()] = (value as num?)?.toInt() ?? 0;
        });
      }
      AppLogger.instance.info('Reset household data done: $counts');
      return counts;
    } catch (e, s) {
      AppLogger.instance.error('Reset household data failed', e, s);
      rethrow;
    }
  }
}

final dataResetRepositoryProvider = Provider<DataResetRepository>((ref) {
  return DataResetRepository(ref.watch(supabaseClientProvider));
});
