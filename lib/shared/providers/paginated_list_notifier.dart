import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/list_pagination.dart';
import '../models/paginated_result.dart';
import 'paginated_list_state.dart';

abstract class PaginatedListNotifier<T> extends Notifier<PaginatedListState<T>> {
  int _requestGeneration = 0;

  @override
  PaginatedListState<T> build() {
    Future.microtask(loadInitial);
    return const PaginatedListState(isLoading: true);
  }

  Future<String?> get householdId async => null;

  Future<PaginatedResult<T>> fetchPage(
    String householdId,
    int offset,
    int limit,
  );

  bool _isCurrent(int generation) => generation == _requestGeneration;

  void _applyState(PaginatedListState<T> next) {
    state = next;
  }

  Future<void> loadInitial() async {
    if (state.isLoading && state.items.isNotEmpty) return;

    final generation = ++_requestGeneration;
    _applyState(state.copyWith(isLoading: true, clearError: true));
    try {
      final id = await householdId;
      if (!_isCurrent(generation)) return;
      if (id == null) {
        _applyState(const PaginatedListState());
        return;
      }
      final result = await fetchPage(id, 0, kListPageSize);
      if (!_isCurrent(generation)) return;
      _applyState(
        PaginatedListState(
          items: result.items,
          hasMore: result.hasMore,
        ),
      );
    } catch (error) {
      if (!_isCurrent(generation)) return;
      _applyState(state.copyWith(isLoading: false, error: error));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    final generation = _requestGeneration;
    final offset = state.items.length;
    _applyState(state.copyWith(isLoadingMore: true, clearError: true));
    try {
      final id = await householdId;
      if (!_isCurrent(generation)) return;
      if (id == null) {
        _applyState(state.copyWith(isLoadingMore: false));
        return;
      }
      final result = await fetchPage(id, offset, kListPageSize);
      if (!_isCurrent(generation)) return;
      _applyState(
        state.copyWith(
          items: [...state.items, ...result.items],
          hasMore: result.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (error) {
      if (!_isCurrent(generation)) return;
      _applyState(state.copyWith(isLoadingMore: false, error: error));
    }
  }

  Future<void> refresh() async {
    _requestGeneration++;
    _applyState(const PaginatedListState(isLoading: true));
    await loadInitial();
  }
}
