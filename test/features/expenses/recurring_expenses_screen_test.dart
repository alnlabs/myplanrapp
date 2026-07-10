import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/expenses/data/recurring_money_rule_repository.dart';
import 'package:myplanr/features/expenses/presentation/recurring_expenses_screen.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('RecurringExpensesScreen widget', () {
    testWidgets('renders recurring rules list', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          recurringExpenseRulesProvider.overrideWith(
            (ref) async => [testRecurringExpenseRule],
          ),
        ],
        child: const RecurringExpensesScreen(),
      );

      expect(find.text(AppStrings.recurringExpenses), findsOneWidget);
      expect(find.text('Rent'), findsOneWidget);
      expect(find.textContaining('auto'), findsOneWidget);
      expect(find.text(AppStrings.addRecurringExpense), findsWidgets);
    });

    testWidgets('shows empty state when no rules', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          recurringExpenseRulesProvider.overrideWith((ref) async => []),
        ],
        child: const RecurringExpensesScreen(),
      );

      expect(find.text(AppStrings.emptyRecurringExpenses), findsOneWidget);
      expect(find.text(AppStrings.emptyRecurringExpensesHint), findsOneWidget);
    });
  });
}
