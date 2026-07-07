import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../shared/models/shopping_list_item.dart';
import '../../auth/data/auth_repository.dart';

class ShoppingRepository {
  ShoppingRepository(this._client);

  final SupabaseClient _client;

  Future<List<ShoppingListItem>> fetchItems(String householdId) async {
    final data = await _client
        .from('shopping_list_items')
        .select()
        .eq('household_id', householdId)
        .order('is_checked')
        .order('created_at', ascending: false);
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

  Future<int> generateFromRecipe(String recipeId) async {
    final result = await _client.rpc<int>('generate_shopping_list_from_recipe',
        params: {'p_recipe_id': recipeId});
    return result;
  }

  Future<void> completeItem(String itemId, {bool restock = true}) async {
    await _client.rpc('complete_shopping_item', params: {
      'p_item_id': itemId,
      'p_restock': restock,
    });
  }
}

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return ShoppingRepository(ref.watch(supabaseClientProvider));
});

final shoppingListProvider = FutureProvider<List<ShoppingListItem>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return [];
  return ref.watch(shoppingRepositoryProvider).fetchItems(householdId);
});
