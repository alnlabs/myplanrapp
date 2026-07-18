import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../shared/constants/list_pagination.dart';
import '../../../shared/models/paginated_result.dart';
import '../../../shared/utils/paginated_page_parser.dart';
import '../../../shared/models/pantry_item.dart';
import '../../auth/data/auth_repository.dart';

class PantryRepository {
  PantryRepository(this._client);

  final SupabaseClient _client;

  Future<PaginatedResult<PantryItem>> fetchItemsPage(
    String householdId, {
    required int offset,
    required int limit,
  }) async {
    final data = await _client
        .from('pantry_items')
        .select()
        .eq('household_id', householdId)
        .order('name')
        .range(offset, offset + limit);
    return _parsePage(data, limit);
  }

  Future<int> fetchItemCount(String householdId) async {
    return _client
        .from('pantry_items')
        .count(CountOption.exact)
        .eq('household_id', householdId);
  }

  Future<PantryItem?> fetchItem(String id) async {
    final data = await _client
        .from('pantry_items')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return PantryItem.fromJson(data);
  }

  PaginatedResult<PantryItem> _parsePage(dynamic data, int limit) {
    final parsed = parsePaginatedPage(data, limit, PantryItem.fromJson);
    return PaginatedResult(items: parsed.items, hasMore: parsed.hasMore);
  }

  Future<PantryItem> createItem(PantryItem item, String householdId) async {
    final userId = _client.auth.currentUser?.id;
    final data = await _client
        .from('pantry_items')
        .insert(item.toInsertJson(householdId, userId))
        .select()
        .single();
    return PantryItem.fromJson(data);
  }

  Future<PantryItem> updateItem(PantryItem item) async {
    final data = await _client
        .from('pantry_items')
        .update(item.toUpdateJson())
        .eq('id', item.id)
        .select()
        .single();
    return PantryItem.fromJson(data);
  }

  Future<void> deleteItem(String id) async {
    await _client.from('pantry_items').delete().eq('id', id);
  }

  Future<StockEvent> applyStockEvent({
    required String itemId,
    required double delta,
    required String reason,
    String? note,
  }) async {
    final data = await _client.rpc('apply_stock_event', params: {
      'p_item_id': itemId,
      'p_delta': delta,
      'p_reason': reason,
      'p_note': note,
    });
    return StockEvent.fromJson(data as Map<String, dynamic>);
  }

  Future<List<StockEvent>> fetchStockEvents(String itemId) async {
    final data = await _client
        .from('stock_events')
        .select()
        .eq('item_id', itemId)
        .order('created_at', ascending: false)
        .limit(kSafetyFetchCap);
    return (data as List)
        .map((e) => StockEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PantryItem>> fetchLowStock(String householdId) async {
    final data = await _client.rpc('check_low_stock', params: {
      'p_household_id': householdId,
    }).limit(kSafetyFetchCap);
    return (data as List)
        .map((e) => PantryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PantryItem>> fetchExpiringSoon(String householdId) async {
    final data = await _client.rpc('check_expiring_soon', params: {
      'p_household_id': householdId,
      'p_days': 3,
    }).limit(kSafetyFetchCap);
    return (data as List)
        .map((e) => PantryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PantryItem> updateAvailabilityStatus(
    String itemId,
    String? status,
  ) async {
    final data = await _client
        .from('pantry_items')
        .update({'availability_status': status})
        .eq('id', itemId)
        .select()
        .single();
    return PantryItem.fromJson(data);
  }
}

final pantryRepositoryProvider = Provider<PantryRepository>((ref) {
  return PantryRepository(ref.watch(supabaseClientProvider));
});

final pantryItemCountProvider = FutureProvider<int>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return 0;
  return ref.watch(pantryRepositoryProvider).fetchItemCount(householdId);
});

final pantryItemProvider =
    FutureProvider.family<PantryItem?, String>((ref, id) async {
  return ref.watch(pantryRepositoryProvider).fetchItem(id);
});

/// First page of items for dropdown pickers (expense form, etc.).
final pantryPickerItemsProvider = FutureProvider<List<PantryItem>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return [];
  final result = await ref.watch(pantryRepositoryProvider).fetchItemsPage(
        householdId,
        offset: 0,
        limit: kPickerPageSize,
      );
  return result.items;
});

final lowStockItemsProvider = FutureProvider<List<PantryItem>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return [];
  return ref.watch(pantryRepositoryProvider).fetchLowStock(householdId);
});

final expiringItemsProvider = FutureProvider<List<PantryItem>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return [];
  return ref.watch(pantryRepositoryProvider).fetchExpiringSoon(householdId);
});

final stockEventsProvider =
    FutureProvider.family<List<StockEvent>, String>((ref, itemId) async {
  return ref.watch(pantryRepositoryProvider).fetchStockEvents(itemId);
});
