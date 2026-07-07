class ShoppingListItem {
  const ShoppingListItem({
    required this.id,
    required this.householdId,
    required this.name,
    this.quantity,
    this.unit,
    required this.source,
    this.isChecked = false,
    this.recipeId,
    this.pantryItemId,
  });

  final String id;
  final String householdId;
  final String name;
  final double? quantity;
  final String? unit;
  final String source;
  final bool isChecked;
  final String? recipeId;
  final String? pantryItemId;

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) {
    return ShoppingListItem(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] != null
          ? (json['quantity'] as num).toDouble()
          : null,
      unit: json['unit'] as String?,
      source: json['source'] as String,
      isChecked: json['is_checked'] as bool? ?? false,
      recipeId: json['recipe_id'] as String?,
      pantryItemId: json['pantry_item_id'] as String?,
    );
  }
}
