import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/providers/paginated_list_state.dart';

void main() {
  group('PaginatedListState', () {
    test('isInitialLoading when loading with empty items', () {
      const state = PaginatedListState<String>(isLoading: true);
      expect(state.isInitialLoading, isTrue);
      expect(state.hasError, isFalse);
    });

    test('hasError when error and no items', () {
      const state = PaginatedListState<String>(error: 'fail');
      expect(state.hasError, isTrue);
      expect(state.isInitialLoading, isFalse);
    });

    test('copyWith updates fields', () {
      const original = PaginatedListState<String>(
        items: ['a'],
        isLoading: false,
        hasMore: true,
      );
      final updated = original.copyWith(
        items: ['a', 'b'],
        isLoadingMore: true,
      );
      expect(updated.items, ['a', 'b']);
      expect(updated.isLoadingMore, isTrue);
      expect(updated.hasMore, isTrue);
    });

    test('copyWith clearError removes error', () {
      const original = PaginatedListState<String>(error: 'oops');
      final updated = original.copyWith(clearError: true);
      expect(updated.error, isNull);
    });
  });
}
