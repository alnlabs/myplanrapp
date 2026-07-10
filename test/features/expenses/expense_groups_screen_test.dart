import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/expenses/data/expense_groups_repository.dart';
import 'package:myplanr/features/expenses/presentation/expense_groups_screen.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('ExpenseGroupsScreen widget', () {
    testWidgets('renders expense groups list', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          expenseGroupsProvider.overrideWith(
            (ref) async => [testSharedExpenseGroup, testOrgExpenseGroup],
          ),
        ],
        child: const ExpenseGroupsScreen(),
      );

      expect(find.text(AppStrings.expenseGroupsTitle), findsOneWidget);
      expect(find.text('Trip to Goa'), findsOneWidget);
      expect(find.text('Home repairs'), findsOneWidget);
      expect(find.text(AppStrings.groupTypeShared), findsOneWidget);
      expect(find.text(AppStrings.addExpenseGroup), findsOneWidget);
    });

    testWidgets('shows empty state when no groups', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          expenseGroupsProvider.overrideWith((ref) async => []),
        ],
        child: const ExpenseGroupsScreen(),
      );

      expect(find.text(AppStrings.emptyExpenseGroups), findsOneWidget);
      expect(find.text(AppStrings.emptyExpenseGroupsHint), findsOneWidget);
    });
  });
}
