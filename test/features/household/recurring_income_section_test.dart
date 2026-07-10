import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/expenses/data/expense_repository.dart';
import 'package:myplanr/features/expenses/data/recurring_money_rule_repository.dart';
import 'package:myplanr/features/household/presentation/recurring_income_section.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  const memberId = 'member-1';

  final baseOverrides = [
    incomeCategoriesProvider.overrideWith((ref) async => testIncomeCategories),
  ];

  group('RecurringIncomeSection widget', () {
    testWidgets('renders recurring income rules', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          ...baseOverrides,
          memberRecurringIncomeProvider(memberId).overrideWith(
            (ref) async => [testRecurringIncomeRule],
          ),
        ],
        child: const Scaffold(
          body: RecurringIncomeSection(
            familyMemberId: memberId,
            householdId: testHouseholdId,
            canEdit: true,
          ),
        ),
      );

      expect(find.text(AppStrings.recurringIncome), findsOneWidget);
      expect(find.text('Acme Corp'), findsOneWidget);
      expect(find.textContaining(AppStrings.nextDue), findsOneWidget);
      expect(find.text(AppStrings.addRecurringIncome), findsOneWidget);
    });

    testWidgets('shows empty state when no rules', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          ...baseOverrides,
          memberRecurringIncomeProvider(memberId).overrideWith((ref) async => []),
        ],
        child: const Scaffold(
          body: RecurringIncomeSection(
            familyMemberId: memberId,
            householdId: testHouseholdId,
            canEdit: false,
          ),
        ),
      );

      expect(find.text(AppStrings.emptyIncome), findsOneWidget);
      expect(find.text(AppStrings.addRecurringIncome), findsNothing);
    });

    testWidgets('opens add dialog when edit is allowed', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          ...baseOverrides,
          memberRecurringIncomeProvider(memberId).overrideWith((ref) async => []),
        ],
        child: const Scaffold(
          body: RecurringIncomeSection(
            familyMemberId: memberId,
            householdId: testHouseholdId,
            canEdit: true,
          ),
        ),
      );

      await tester.tap(find.text(AppStrings.addRecurringIncome));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.addRecurringIncome), findsWidgets);
      expect(find.text(AppStrings.incomeSource), findsOneWidget);
      expect(find.text(AppStrings.amount), findsOneWidget);
      expect(find.text(AppStrings.incomeCategory), findsOneWidget);
    });
  });
}
