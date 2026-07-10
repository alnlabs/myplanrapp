import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/utils/list_sharing.dart';

void main() {
  group('formatShopListForSharing', () {
    test('returns title only when list is empty', () {
      expect(
        formatShopListForSharing(title: 'Shop list', itemNames: []),
        'Shop list',
      );
    });

    test('formats bullet list', () {
      final text = formatShopListForSharing(
        title: 'Groceries',
        itemNames: ['Milk', 'Bread'],
      );
      expect(text, 'Groceries\n• Milk\n• Bread');
    });
  });
}
