import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myplanr/features/expenses/data/expenses_list_provider.dart';
import 'package:myplanr/features/pantry/data/pantry_items_list_provider.dart';
import 'package:myplanr/features/plans/data/plans_list_provider.dart';
import 'package:myplanr/shared/models/expense.dart';
import 'package:myplanr/shared/models/paginated_result.dart';
import 'package:myplanr/shared/models/pantry_item.dart';
import 'package:myplanr/shared/models/plan.dart';
import 'package:myplanr/shared/providers/paginated_list_state.dart';

import 'test_fixtures.dart';

class StubExpensesListNotifier extends ExpensesListNotifier {
  StubExpensesListNotifier({this.items = const []});

  final List<Expense> items;

  @override
  PaginatedListState<Expense> build() => PaginatedListState(items: items);

  @override
  Future<String?> get householdId async => testHouseholdId;

  @override
  Future<PaginatedResult<Expense>> fetchPage(
    String householdId,
    int offset,
    int limit,
  ) async {
    return PaginatedResult(items: items, hasMore: false);
  }
}

class StubPantryItemsListNotifier extends PantryItemsListNotifier {
  StubPantryItemsListNotifier({this.items = const []});

  final List<PantryItem> items;

  @override
  PaginatedListState<PantryItem> build() => PaginatedListState(items: items);

  @override
  Future<String?> get householdId async => testHouseholdId;

  @override
  Future<PaginatedResult<PantryItem>> fetchPage(
    String householdId,
    int offset,
    int limit,
  ) async {
    return PaginatedResult(items: items, hasMore: false);
  }
}

class StubPlansListNotifier extends PlansListNotifier {
  StubPlansListNotifier({this.items = const []});

  final List<Plan> items;

  @override
  PaginatedListState<Plan> build() => PaginatedListState(items: items);

  @override
  Future<String?> get householdId async => testHouseholdId;

  @override
  Future<PaginatedResult<Plan>> fetchPage(
    String householdId,
    int offset,
    int limit,
  ) async {
    return PaginatedResult(items: items, hasMore: false);
  }
}
