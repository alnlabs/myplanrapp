import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/models/paginated_result.dart';

void main() {
  group('PaginatedResult', () {
    test('holds items and hasMore flag', () {
      const result = PaginatedResult<String>(
        items: ['a', 'b'],
        hasMore: true,
      );
      expect(result.items, ['a', 'b']);
      expect(result.hasMore, isTrue);
    });
  });
}
