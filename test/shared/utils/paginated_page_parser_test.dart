import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/models/expense.dart';
import 'package:myplanr/shared/utils/paginated_page_parser.dart';

void main() {
  group('parsePaginatedPage', () {
    test('returns all rows when count equals limit', () {
      final data = [
        {'id': '1', 'name': 'A', 'category_kind': 'expense'},
        {'id': '2', 'name': 'B', 'category_kind': 'expense'},
      ];
      final result = parsePaginatedPage(
        data,
        2,
        ExpenseCategory.fromJson,
      );
      expect(result.items, hasLength(2));
      expect(result.hasMore, isFalse);
      expect(result.items.first.name, 'A');
    });

    test('trims to limit and sets hasMore when extra row present', () {
      final data = List.generate(
        4,
        (i) => {'id': '$i', 'name': 'Item $i', 'category_kind': 'expense'},
      );
      final result = parsePaginatedPage(
        data,
        3,
        ExpenseCategory.fromJson,
      );
      expect(result.items, hasLength(3));
      expect(result.hasMore, isTrue);
      expect(result.items.last.id, '2');
    });

    test('handles empty list', () {
      final result = parsePaginatedPage(
        <Map<String, dynamic>>[],
        10,
        ExpenseCategory.fromJson,
      );
      expect(result.items, isEmpty);
      expect(result.hasMore, isFalse);
    });
  });

  group('PaginatedParseResult', () {
    test('holds items and hasMore flag', () {
      const result = PaginatedParseResult<String>(
        items: ['a'],
        hasMore: true,
      );
      expect(result.items, ['a']);
      expect(result.hasMore, isTrue);
    });
  });
}
