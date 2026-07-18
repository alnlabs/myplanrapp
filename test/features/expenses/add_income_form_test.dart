import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/expenses/data/expense_repository.dart';
import 'package:myplanr/features/expenses/presentation/add_income_screen.dart';
import 'package:myplanr/features/household/data/family_repository.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  final overrides = [
    incomeCategoriesProvider.overrideWith((ref) async => testIncomeCategories),
    familyRosterProvider.overrideWith((ref) async => testFamilyMembers),
    currentUserFamilyMemberProvider
        .overrideWith((ref) async => testFamilyMembers.first),
  ];

  group('AddIncomeScreen widget', () {
    testWidgets('shows validation errors for empty source and amount', (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides,
        child: const AddIncomeScreen(),
      );

      await tapSave(tester);

      expect(find.text(AppStrings.requiredField), findsNWidgets(2));
    });

    testWidgets('rejects zero and invalid amount', (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides,
        child: const AddIncomeScreen(),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'Salary');
      await tester.enterText(find.byType(TextFormField).at(1), '0');
      await tester.pumpAndSettle();
      await tapSave(tester);
      expect(find.text(AppStrings.invalidAmount), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(1), 'not-a-number');
      await tester.pumpAndSettle();
      await tapSave(tester);
      expect(find.text(AppStrings.invalidAmount), findsOneWidget);
    });

    testWidgets('prefills initial income source and amount', (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides,
        child: const AddIncomeScreen(
          initialIncomeSource: 'Freelance',
          initialAmount: 5000,
          initialFamilyMemberId: 'member-2',
        ),
      );

      expect(find.text('Freelance'), findsOneWidget);
      expect(find.text('5000.0'), findsOneWidget);
      expect(find.text('Sam'), findsWidgets);
    });

    testWidgets('shows category validation when categories are empty', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          incomeCategoriesProvider.overrideWith((ref) async => []),
          familyRosterProvider.overrideWith((ref) async => testFamilyMembers),
          currentUserFamilyMemberProvider
              .overrideWith((ref) async => testFamilyMembers.first),
        ],
        child: const AddIncomeScreen(),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'Bonus');
      await tester.enterText(find.byType(TextFormField).at(1), '1000');
      await tester.pumpAndSettle();
      await tapSave(tester);

      expect(find.text(AppStrings.selectCategory), findsOneWidget);
    });

    testWidgets('note field is optional', (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides,
        child: const AddIncomeScreen(),
      );

      final noteField = find.byType(TextFormField).last;
      await tester.enterText(noteField, 'Monthly payout');
      await tester.pumpAndSettle();

      expect(find.text('Monthly payout'), findsOneWidget);
    });
  });
}
