import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/expenses/presentation/expense_group_form_screen.dart';
import 'package:myplanr/features/household/data/family_repository.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  final overrides = [
    familyRosterProvider.overrideWith((ref) async => testFamilyMembers),
  ];

  group('ExpenseGroupFormScreen widget', () {
    testWidgets('requires group name', (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides,
        child: const ExpenseGroupFormScreen(),
      );

      await tapSave(tester);
      expect(find.text(AppStrings.requiredField), findsOneWidget);
    });

    testWidgets('shows shared group minimum member error', (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides,
        child: const ExpenseGroupFormScreen(),
      );

      await tester.enterText(find.byType(TextFormField).first, 'Trip');
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.groupType));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.groupTypeShared).last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alex Parent'));
      await tester.pumpAndSettle();

      await tapSave(tester);
      expect(find.text(AppStrings.sharedGroupMinMembers), findsOneWidget);
    });

    testWidgets('renders family roster checkboxes', (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides,
        child: const ExpenseGroupFormScreen(),
      );

      expect(find.text('Alex Parent'), findsOneWidget);
      expect(find.text('Sam'), findsOneWidget);
      expect(find.text(AppStrings.addGuestMember), findsOneWidget);
    });
  });
}
