import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/expenses/data/expense_groups_repository.dart';
import 'package:myplanr/features/expenses/data/expense_repository.dart';
import 'package:myplanr/features/expenses/data/expenses_list_provider.dart';
import 'package:myplanr/features/expenses/data/money_list_filter_provider.dart';
import 'package:myplanr/features/expenses/data/recurring_money_rule_repository.dart';
import 'package:myplanr/features/expenses/presentation/expense_summary_screen.dart';
import 'package:myplanr/features/expenses/presentation/expenses_screen.dart';
import 'package:myplanr/features/household/data/family_repository.dart';

import '../../helpers/provider_overrides.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/stub_notifiers.dart';
import '../../helpers/stub_repositories.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  final expenseOverrides = [
    ...testAuthOverrides,
    expensesListProvider.overrideWith(
      () => StubExpensesListNotifier(items: [testGroupExpense]),
    ),
    moneySummaryProvider.overrideWith((ref) async => testMoneySummary),
    memberIncomeSummaryProvider.overrideWith((ref) async => []),
    dueRecurringIncomeProvider.overrideWith((ref) async => []),
    dueRecurringExpenseProvider.overrideWith((ref) async => []),
    recurringExpenseRulesProvider.overrideWith((ref) async => []),
    expenseSummaryProvider.overrideWith((ref) async => testExpenseSummaryRows),
    familyRosterProvider.overrideWith((ref) async => testFamilyMembers),
    expenseGroupsProvider.overrideWith((ref) async => []),
    recurringMoneyRuleRepositoryProvider.overrideWith(
      (ref) => StubRecurringMoneyRuleRepository(),
    ),
  ];

  group('ExpensesScreen widget', () {
    testWidgets('renders money summary and expense list', (tester) async {
      await pumpShellTestApp(
        tester,
        overrides: expenseOverrides,
        child: const ExpensesScreen(),
      );

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text(AppStrings.expensesTitle),
        ),
        findsOneWidget,
      );
      expect(find.text('Dinner'), findsOneWidget);
      expect(find.text(AppStrings.addExpense), findsOneWidget);
    });
  });

  group('ExpenseSummaryScreen widget', () {
    testWidgets('renders category breakdown', (tester) async {
      await pumpTestApp(
        tester,
        overrides: expenseOverrides,
        child: const ExpenseSummaryScreen(),
      );

      expect(find.text(AppStrings.summaryTitle), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Misc'), findsOneWidget);
    });
  });
}
