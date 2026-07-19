import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../shared/constants/list_pagination.dart';
import '../../../shared/constants/pantry_availability.dart';
import '../../../shared/models/shopping_list_item.dart';
import '../../../shared/utils/batch_delete.dart';

class ShoppingRepository {
  ShoppingRepository(this._client);

  final SupabaseClient _client;

  Future<List<ShoppingListItem>> fetchItems(String householdId) async {
    final data = await _client
        .from('shopping_list_items')
        .select()
        .eq('household_id', householdId)
        .eq('is_checked', false)
        .order('created_at', ascending: false)
        .limit(kSafetyFetchCap);
    return (data as List)
        .map((e) => ShoppingListItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addItem({
    required String householdId,
    required String name,
    double? quantity,
    String? unit,
    String source = 'manual',
    String? recipeId,
    String? pantryItemId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    await _client.from('shopping_list_items').insert({
      'household_id': householdId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'source': source,
      'recipe_id': recipeId,
      'pantry_item_id': pantryItemId,
      'created_by': userId,
    });
  }

  Future<void> toggleChecked(String id, bool isChecked) async {
    await _client
        .from('shopping_list_items')
        .update({'is_checked': isChecked})
        .eq('id', id);
  }

  Future<void> deleteItem(String id) async {
    await _client.from('shopping_list_items').delete().eq('id', id);
  }

  Future<void> deleteItems(List<String> ids) async {
    await deleteByIds(_client, 'shopping_list_items', ids);
  }

  Future<void> clearChecked(String householdId) async {
    await _client
        .from('shopping_list_items')
        .delete()
        .eq('household_id', householdId)
        .eq('is_checked', true);
  }

  Future<int> generateFromLowStock(String householdId) async {
    final result = await _client.rpc<int>('generate_shopping_list_from_low_stock',
        params: {'p_household_id': householdId});
    return result;
  }

  Future<void> syncLowStockToShop(String householdId) async {
    try {
      await _client.rpc('sync_shopping_list_from_pantry', params: {
        'p_household_id': householdId,
      });
    } catch (_) {
      try {
        await generateFromLowStock(householdId);
      } catch (_) {
        // Shop sync should not break pantry or other flows.
      }
    }
  }

  Future<void> removeLowStockShopItemsForPantry({
    required String householdId,
    required String pantryItemId,
    required String name,
  }) async {
    await _client
        .from('shopping_list_items')
        .delete()
        .eq('household_id', householdId)
        .eq('is_checked', false)
        .eq('source', 'low_stock')
        .or('pantry_item_id.eq.$pantryItemId,name.ilike.$name');
  }

  Future<void> completeItem(
    String itemId, {
    bool restock = true,
    String? pantryItemId,
  }) async {
    try {
      await _client.rpc('complete_shopping_item', params: {
        'p_item_id': itemId,
        'p_restock': restock,
      });
    } catch (_) {
      // Fall through so local cleanup still runs if RPC is unavailable.
    }

    // Always remove from shop list (covers older DB functions that only checked).
    await deleteItem(itemId);

    if (pantryItemId != null) {
      await _client
          .from('pantry_items')
          .update({'availability_status': PantryAvailability.fine})
          .eq('id', pantryItemId);
    }
  }
}

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return ShoppingRepository(ref.watch(supabaseClientProvider));
});
