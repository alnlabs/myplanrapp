import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/expense.dart';
import '../../../shared/models/paginated_result.dart';
import '../../../shared/providers/paginated_list_notifier.dart';
import '../../../shared/providers/paginated_list_state.dart';
import '../../../shared/utils/offline_guard.dart';
import '../../auth/data/auth_repository.dart';
import 'expense_date_filter_provider.dart';
import 'expense_repository.dart';
import 'expense_view_provider.dart';
import 'money_list_filter_provider.dart';
import 'recurring_money_rule_repository.dart';

class ExpensesListNotifier extends PaginatedListNotifier<Expense> {
  @override
  Future<String?> get householdId async {
    final profile = await ref.read(userProfileProvider.future);
    return profile?.activeHouseholdId;
  }

  @override
  Future<PaginatedResult<Expense>> fetchPage(
    String householdId,
    int offset,
    int limit,
  ) {
    final filters = ref.read(moneyListFilterProvider);
    final range = ref.read(expenseDateRangeProvider);
    final view = ref.read(expenseViewProvider);
    return ref.read(expenseRepositoryProvider).fetchExpensesPage(
          householdId,
          offset: offset,
          limit: limit,
          entryType: filters.entryType,
          familyMemberId: filters.familyMemberId,
          startDate: range.start,
          endDate: range.end,
          groupId: view.groupFilterId,
          scope: view.scope,
        );
  }
}

final expensesListProvider =
    NotifierProvider<ExpensesListNotifier, PaginatedListState<Expense>>(
  ExpensesListNotifier.new,
);

Future<void> refreshExpensesData(WidgetRef ref) async {
  await ref.read(expensesListProvider.notifier).refresh();
  ref.invalidate(expenseSummaryProvider);
  ref.invalidate(moneySummaryProvider);
  ref.invalidate(memberIncomeSummaryProvider);
  ref.invalidate(hasAnyExpenseProvider);
  ref.invalidate(dueRecurringIncomeProvider);
  ref.invalidate(dueRecurringExpenseProvider);
  ref.invalidate(recurringExpenseRulesProvider);
}

Future<int> processAutoLogRecurringExpenses(WidgetRef ref) async {
  final profile = await ref.read(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return 0;
  try {
    ref.ensureOnline();
    final count = await ref
        .read(recurringMoneyRuleRepositoryProvider)
        .processAutoLogDueExpenses(householdId);
    if (count > 0) {
      await refreshExpensesData(ref);
    }
    return count;
  } catch (_) {
    return 0;
  }
}
