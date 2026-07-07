import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../shared/models/recipe.dart';
import '../../auth/data/auth_repository.dart';

class RecipeRepository {
  RecipeRepository(this._client);

  final SupabaseClient _client;

  Future<List<Recipe>> fetchRecipes(String householdId) async {
    final data = await _client
        .from('recipes')
        .select('*, recipe_ingredients(*)')
        .eq('household_id', householdId)
        .order('name');
    return (data as List)
        .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Recipe> fetchRecipe(String id) async {
    final data = await _client
        .from('recipes')
        .select('*, recipe_ingredients(*)')
        .eq('id', id)
        .single();
    return Recipe.fromJson(data);
  }

  Future<Recipe> createRecipe({
    required String householdId,
    required String name,
    required int servings,
    String? instructions,
    required List<RecipeIngredient> ingredients,
  }) async {
    final userId = _client.auth.currentUser?.id;
    final recipeData = await _client
        .from('recipes')
        .insert({
          'household_id': householdId,
          'name': name,
          'servings': servings,
          'instructions': instructions,
          'created_by': userId,
        })
        .select()
        .single();
    final recipeId = recipeData['id'] as String;

    if (ingredients.isNotEmpty) {
      await _client.from('recipe_ingredients').insert(
            ingredients
                .asMap()
                .entries
                .map((e) => e.value.toJson(recipeId)..['sort_order'] = e.key)
                .toList(),
          );
    }

    return fetchRecipe(recipeId);
  }

  Future<void> deleteRecipe(String id) async {
    await _client.from('recipes').delete().eq('id', id);
  }

  Future<Recipe> updateRecipe({
    required String id,
    required String name,
    required int servings,
    String? instructions,
    required List<RecipeIngredient> ingredients,
  }) async {
    await _client.from('recipes').update({
      'name': name,
      'servings': servings,
      'instructions': instructions,
    }).eq('id', id);

    await _client.from('recipe_ingredients').delete().eq('recipe_id', id);

    if (ingredients.isNotEmpty) {
      await _client.from('recipe_ingredients').insert(
            ingredients
                .asMap()
                .entries
                .map((e) => e.value.toJson(id)..['sort_order'] = e.key)
                .toList(),
          );
    }

    return fetchRecipe(id);
  }

  Future<void> seedDefaultRecipes(String householdId) async {
    final existing = await fetchRecipes(householdId);
    if (existing.isNotEmpty) return;

    await createRecipe(
      householdId: householdId,
      name: 'Chicken Biryani',
      servings: 4,
      instructions:
          'Marinate chicken, parboil rice, layer and dum cook for 25 minutes.',
      ingredients: const [
        RecipeIngredient(name: 'Basmati rice', quantity: 500, unit: 'g'),
        RecipeIngredient(name: 'Chicken', quantity: 500, unit: 'g'),
        RecipeIngredient(name: 'Onion', quantity: 3, unit: 'pcs'),
        RecipeIngredient(name: 'Tomato', quantity: 2, unit: 'pcs'),
        RecipeIngredient(name: 'Biryani masala', quantity: 2, unit: 'pack'),
      ],
    );

    await createRecipe(
      householdId: householdId,
      name: 'Dal Tadka',
      servings: 4,
      instructions: 'Pressure cook dal, prepare tadka, mix and simmer.',
      ingredients: const [
        RecipeIngredient(name: 'Toor dal', quantity: 200, unit: 'g'),
        RecipeIngredient(name: 'Onion', quantity: 1, unit: 'pcs'),
        RecipeIngredient(name: 'Tomato', quantity: 1, unit: 'pcs'),
        RecipeIngredient(name: 'Turmeric', quantity: 5, unit: 'g'),
      ],
    );
  }

  Future<List<RecipeAvailability>> checkAvailability(
    String recipeId,
    String householdId,
  ) async {
    final data = await _client.rpc('check_recipe_availability', params: {
      'p_recipe_id': recipeId,
      'p_household_id': householdId,
    });
    return (data as List)
        .map((e) => RecipeAvailability.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> cookAndDeduct(String recipeId, {double scale = 1.0}) async {
    final recipe = await fetchRecipe(recipeId);
    final availability = await checkAvailability(
      recipeId,
      recipe.householdId,
    );

    for (final row in availability) {
      if (!row.isSufficient || row.pantryItemId == null) continue;
      final amount = row.requiredQuantity * scale;
      await _client.rpc('apply_stock_event', params: {
        'p_item_id': row.pantryItemId,
        'p_delta': -amount,
        'p_reason': 'used',
        'p_note': 'Cooked ${recipe.name}',
      });
    }
  }
}

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepository(ref.watch(supabaseClientProvider));
});

final recipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return [];
  return ref.watch(recipeRepositoryProvider).fetchRecipes(householdId);
});

final recipeAvailabilityProvider = FutureProvider.family<
    List<RecipeAvailability>, String>((ref, recipeId) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return [];
  return ref
      .watch(recipeRepositoryProvider)
      .checkAvailability(recipeId, householdId);
});
