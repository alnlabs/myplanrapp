class Recipe {
  const Recipe({
    required this.id,
    required this.householdId,
    required this.name,
    required this.servings,
    this.instructions,
    this.ingredients = const [],
  });

  final String id;
  final String householdId;
  final String name;
  final int servings;
  final String? instructions;
  final List<RecipeIngredient> ingredients;

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final rawIngredients = json['recipe_ingredients'] as List<dynamic>?;
    return Recipe(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      name: json['name'] as String,
      servings: json['servings'] as int,
      instructions: json['instructions'] as String?,
      ingredients: rawIngredients
              ?.map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class RecipeIngredient {
  const RecipeIngredient({
    this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.pantryItemId,
    this.sortOrder = 0,
  });

  final String? id;
  final String name;
  final double quantity;
  final String unit;
  final String? pantryItemId;
  final int sortOrder;

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      id: json['id'] as String?,
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      pantryItemId: json['pantry_item_id'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson(String recipeId) {
    return {
      if (id != null) 'id': id,
      'recipe_id': recipeId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'pantry_item_id': pantryItemId,
      'sort_order': sortOrder,
    };
  }
}

class RecipeAvailability {
  const RecipeAvailability({
    required this.ingredientId,
    required this.ingredientName,
    required this.requiredQuantity,
    required this.unit,
    required this.availableQuantity,
    required this.status,
    required this.gap,
    this.pantryItemId,
  });

  final String ingredientId;
  final String ingredientName;
  final double requiredQuantity;
  final String unit;
  final double availableQuantity;
  final String status;
  final double gap;
  final String? pantryItemId;

  bool get isSufficient => status == 'sufficient';
  bool get isInsufficient => status == 'insufficient';
  bool get isMissing => status == 'missing';

  factory RecipeAvailability.fromJson(Map<String, dynamic> json) {
    return RecipeAvailability(
      ingredientId: json['ingredient_id'] as String,
      ingredientName: json['ingredient_name'] as String,
      requiredQuantity: (json['required_quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      availableQuantity: (json['available_quantity'] as num).toDouble(),
      status: json['status'] as String,
      gap: (json['gap'] as num).toDouble(),
      pantryItemId: json['pantry_item_id'] as String?,
    );
  }
}
