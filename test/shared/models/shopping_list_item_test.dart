import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/models/shopping_list_item.dart';

void main() {
  group('ShoppingListItem.fromJson', () {
    test('parses optional quantity and flags', () {
      final item = ShoppingListItem.fromJson({
        'id': 's1',
        'household_id': 'hh',
        'name': 'Milk',
        'quantity': 2,
        'unit': 'L',
        'source': 'manual',
        'is_checked': true,
        'recipe_id': 'r1',
        'pantry_item_id': 'p1',
      });
      expect(item.name, 'Milk');
      expect(item.quantity, 2);
      expect(item.isChecked, isTrue);
      expect(item.recipeId, 'r1');
      expect(item.pantryItemId, 'p1');
    });

    test('defaults isChecked to false', () {
      final item = ShoppingListItem.fromJson({
        'id': 's1',
        'household_id': 'hh',
        'name': 'Bread',
        'source': 'pantry',
      });
      expect(item.isChecked, isFalse);
      expect(item.quantity, isNull);
    });
  });
}
