import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/expenses/data/expense_repository.dart';
import 'package:myplanr/features/expenses/presentation/add_recurring_expense_screen.dart';
import 'package:myplanr/features/subscriptions/data/subscription_repository.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  final overrides = [
    expenseCategoriesProvider.overrideWith((ref) async => testExpenseCategories),
    subscriptionsProvider.overrideWith((ref) async => [testSubscription]),
  ];

  group('AddRecurringExpenseScreen widget', () {
    testWidgets('shows validation errors for empty title and amount', (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides,
        child: const AddRecurringExpenseScreen(),
      );

      await tapSave(tester);

      expect(find.text(AppStrings.requiredField), findsNWidgets(2));
    });

    testWidgets('rejects invalid amount', (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides,
        child: const AddRecurringExpenseScreen(),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'Rent');
      await tester.enterText(find.byType(TextFormField).at(1), '-5');
      await tester.pumpAndSettle();
      await tapSave(tester);

      expect(find.text(AppStrings.invalidAmount), findsOneWidget);
    });

    testWidgets('shows category validation when categories are empty', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          expenseCategoriesProvider.overrideWith((ref) async => []),
          subscriptionsProvider.overrideWith((ref) async => []),
        ],
        child: const AddRecurringExpenseScreen(),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'Internet');
      await tester.enterText(find.byType(TextFormField).at(1), '999');
      await tester.pumpAndSettle();
      await tapSave(tester);

      expect(find.text(AppStrings.selectCategory), findsOneWidget);
    });

    testWidgets('renders frequency and subscription fields', (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides,
        child: const AddRecurringExpenseScreen(),
      );

      expect(find.text(AppStrings.frequencyMonthly), findsOneWidget);
      expect(find.text(AppStrings.linkedSubscription), findsOneWidget);
      expect(find.text(AppStrings.autoLogExpense), findsOneWidget);

      await tester.tap(find.text(AppStrings.linkedSubscription));
      await tester.pumpAndSettle();
      expect(find.text('Netflix'), findsOneWidget);
    });

    testWidgets('shows monthly due day when frequency is monthly', (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides,
        child: const AddRecurringExpenseScreen(),
      );

      expect(find.text(AppStrings.dueDay), findsOneWidget);
    });

    testWidgets('note field is optional', (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides,
        child: const AddRecurringExpenseScreen(),
      );

      final noteField = find.byType(TextFormField).last;
      await tester.enterText(noteField, 'Auto debit');
      await tester.pumpAndSettle();

      expect(find.text('Auto debit'), findsOneWidget);
    });
  });
}
