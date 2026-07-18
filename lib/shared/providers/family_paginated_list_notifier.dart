import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/list_pagination.dart';
import '../models/paginated_result.dart';
import 'paginated_list_state.dart';

/// Family variant of [PaginatedListNotifier] for lists that are scoped by an
/// argument (e.g. a group id + date range). Subclasses read [arg] to build
/// their query.
abstract class FamilyPaginatedListNotifier<T, Arg>
    extends FamilyNotifier<PaginatedListState<T>, Arg> {
  int _requestGeneration = 0;

  @override
  PaginatedListState<T> build(Arg arg) {
    Future.microtask(loadInitial);
    return PaginatedListState<T>(isLoading: true);
  }

  Future<PaginatedResult<T>> fetchPage(int offset, int limit);

  bool _isCurrent(int generation) => generation == _requestGeneration;

  Future<void> loadInitial() async {
    if (state.isLoading && state.items.isNotEmpty) return;

    final generation = ++_requestGeneration;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await fetchPage(0, kListPageSize);
      if (!_isCurrent(generation)) return;
      state = PaginatedListState<T>(
        items: result.items,
        hasMore: result.hasMore,
      );
    } catch (error) {
      if (!_isCurrent(generation)) return;
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    final generation = _requestGeneration;
    final offset = state.items.length;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final result = await fetchPage(offset, kListPageSize);
      if (!_isCurrent(generation)) return;
      state = state.copyWith(
        items: [...state.items, ...result.items],
        hasMore: result.hasMore,
        isLoadingMore: false,
      );
    } catch (error) {
      if (!_isCurrent(generation)) return;
      state = state.copyWith(isLoadingMore: false, error: error);
    }
  }

  Future<void> refresh() async {
    _requestGeneration++;
    state = PaginatedListState<T>(isLoading: true);
    await loadInitial();
  }
}
