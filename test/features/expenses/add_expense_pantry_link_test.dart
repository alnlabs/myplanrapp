import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/expenses/data/expense_groups_repository.dart';
import 'package:myplanr/features/expenses/data/expense_repository.dart';
import 'package:myplanr/features/expenses/presentation/add_expense_screen.dart';
import 'package:myplanr/features/pantry/data/pantry_repository.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('AddExpenseScreen pantry link', () {
    testWidgets('shows pantry picker when link toggle enabled', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          expenseCategoriesProvider.overrideWith((ref) async => testExpenseCategories),
          expenseGroupsProvider.overrideWith((ref) async => []),
          pantryPickerItemsProvider.overrideWith((ref) async => [testPantryItem]),
        ],
        child: const AddExpenseScreen(),
      );

      await tester.ensureVisible(find.text(AppStrings.linkToPantry));
      await tester.tap(find.text(AppStrings.linkToPantry));
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
    });
  });
}
