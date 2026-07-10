import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/expenses/data/expense_repository.dart';
import 'package:myplanr/features/expenses/data/expense_groups_repository.dart';
import 'package:myplanr/features/expenses/presentation/add_expense_screen.dart';

import '../../helpers/provider_overrides.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/stub_repositories.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  late StubExpenseRepository expenseRepo;

  List<Override> overrides() => [
        ...testAuthOverrides,
        expenseRepositoryProvider.overrideWithValue(expenseRepo),
        expenseCategoriesProvider.overrideWith((ref) async => testExpenseCategories),
        expenseGroupsProvider.overrideWith((ref) async => []),
      ];

  setUp(() {
    expenseRepo = StubExpenseRepository();
  });

  group('AddExpenseScreen widget', () {
    testWidgets('shows validation errors for empty title and amount', (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides(),
        child: const AddExpenseScreen(),
      );

      await tapSave(tester);

      expect(find.text(AppStrings.requiredField), findsNWidgets(2));
    });

    testWidgets('rejects zero amount', (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides(),
        child: const AddExpenseScreen(),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'Lunch');
      await tester.enterText(find.byType(TextFormField).at(1), '0');
      await tester.pumpAndSettle();
      await tapSave(tester);

      expect(find.text(AppStrings.invalidAmount), findsOneWidget);
    });

    testWidgets('rejects invalid amount text', (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides(),
        child: const AddExpenseScreen(),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'Lunch');
      await tester.enterText(find.byType(TextFormField).at(1), 'abc');
      await tester.pumpAndSettle();
      await tapSave(tester);

      expect(find.text(AppStrings.invalidAmount), findsOneWidget);
    });

    testWidgets('prefills initial title and amount', (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides(),
        child: const AddExpenseScreen(
          initialTitle: 'Coffee',
          initialAmount: 120,
        ),
      );

      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('120.0'), findsOneWidget);
    });

    testWidgets('shows category validation when categories are empty', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          ...testAuthOverrides,
          expenseRepositoryProvider.overrideWithValue(expenseRepo),
          expenseCategoriesProvider.overrideWith((ref) async => []),
          expenseGroupsProvider.overrideWith((ref) async => []),
        ],
        child: const AddExpenseScreen(),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'Dinner');
      await tester.enterText(find.byType(TextFormField).at(1), '250');
      await tester.pumpAndSettle();
      await tapSave(tester);

      expect(find.text(AppStrings.selectCategory), findsOneWidget);
    });

    testWidgets('saves valid expense with category and note', (tester) async {
      await pumpPushedScreen(
        tester,
        overrides: overrides(),
        screen: const AddExpenseScreen(),
      );

      await enterTextByLabel(tester, AppStrings.expenseTitle, 'Team lunch');
      await enterTextByLabel(tester, AppStrings.amount, '450');
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Misc').last);
      await tester.pumpAndSettle();

      final noteField = find.byType(TextFormField).last;
      await tester.ensureVisible(noteField);
      await tester.enterText(noteField, 'Friday outing');
      await tester.pumpAndSettle();

      await tapSave(tester);

      expect(expenseRepo.lastCreatedTitle, 'Team lunch');
      expect(expenseRepo.lastCreatedAmount, 450);
      expect(expenseRepo.lastCreatedCategoryId, 'cat-misc');
      expect(expenseRepo.lastCreatedNote, 'Friday outing');
      expect(find.byKey(const Key('open_pushed_screen')), findsOneWidget);
    });

    testWidgets('category dropdown changes selected category', (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides(),
        child: const AddExpenseScreen(),
      );

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Misc').last);
      await tester.pumpAndSettle();

      expect(find.text('Misc'), findsWidgets);
    });

    testWidgets('note field accepts optional text without validation error',
        (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides(),
        child: const AddExpenseScreen(),
      );

      final noteField = find.byType(TextFormField).last;
      await tester.ensureVisible(noteField);
      await tester.enterText(noteField, 'Team lunch');
      await tester.pumpAndSettle();

      expect(find.text('Team lunch'), findsOneWidget);
    });
  });
}
