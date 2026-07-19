import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/expenses/data/expense_groups_repository.dart';
import 'package:myplanr/features/expenses/data/expense_repository.dart';
import 'package:myplanr/features/expenses/data/expense_view_provider.dart';
import 'package:myplanr/features/expenses/data/expense_date_filter.dart';
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
  List<Override> buildExpenseOverrides({List<dynamic> groups = const []}) {
    return [
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
      expenseHistoryProvider.overrideWith((ref) async => const []),
      expenseComparisonProvider.overrideWith(
        (ref) async => const ExpenseComparison(
          preset: ExpenseDatePreset.month,
          currentSpent: 0,
          previousSpent: 0,
        ),
      ),
      familyRosterProvider.overrideWith((ref) async => testFamilyMembers),
      expenseGroupsProvider.overrideWith((ref) async => groups.cast()),
      recurringMoneyRuleRepositoryProvider.overrideWith(
        (ref) => StubRecurringMoneyRuleRepository(),
      ),
    ];
  }

  final expenseOverrides = buildExpenseOverrides();

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
          matching: find.text(AppStrings.viewMoneyAll),
        ),
        findsOneWidget,
      );
      expect(find.text('Dinner'), findsOneWidget);
      expect(find.text(AppStrings.addExpense), findsOneWidget);
    });

    testWidgets('view dropdown switches to the Groups hub', (tester) async {
      await pumpShellTestApp(
        tester,
        overrides: buildExpenseOverrides(groups: [testSharedExpenseGroup]),
        child: const ExpensesScreen(),
      );
      await tester.pumpAndSettle();

      // The compact view selector lives in the app bar.
      expect(find.byType(PopupMenuButton<ExpenseViewKind>), findsOneWidget);

      await tester.tap(find.byType(PopupMenuButton<ExpenseViewKind>));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.viewMoneyPersonal), findsOneWidget);
      expect(find.text(AppStrings.viewMoneyGroups), findsOneWidget);

      await tester.tap(find.text(AppStrings.viewMoneyGroups).last);
      await tester.pumpAndSettle();

      expect(find.text(testSharedExpenseGroup.name), findsOneWidget);
    });

    testWidgets('view subtitle changes with the selected view', (tester) async {
      await pumpShellTestApp(
        tester,
        overrides: expenseOverrides,
        child: const ExpensesScreen(),
      );
      await tester.pumpAndSettle();

      // Default "All" view shows its own subtitle.
      expect(find.text(AppStrings.viewMoneyAllHint), findsOneWidget);
      expect(find.text(AppStrings.viewMoneyPersonalHint), findsNothing);

      await tester.tap(find.byType(PopupMenuButton<ExpenseViewKind>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.viewMoneyPersonal).last);
      await tester.pumpAndSettle();

      // Switching to Personal updates the subtitle under the selector.
      expect(find.text(AppStrings.viewMoneyPersonalHint), findsOneWidget);
      expect(find.text(AppStrings.viewMoneyAllHint), findsNothing);
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
