import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/expenses/data/expense_groups_repository.dart';
import 'package:myplanr/features/expenses/presentation/expense_group_fields.dart';
import 'package:myplanr/shared/models/expense_group.dart';

import '../../helpers/pump_app.dart';

void main() {
  final sharedGroup = ExpenseGroup(
    id: 'group-1',
    householdId: 'hh-1',
    name: 'Trip',
    groupType: 'shared',
  );

  final overrides = [
    expenseGroupsProvider.overrideWith((ref) async => [sharedGroup]),
    expenseGroupProvider('group-1')
        .overrideWith((ref) async => sharedGroup),
    expenseGroupMembersProvider('group-1').overrideWith(
      (ref) async => const [
        ExpenseGroupMember(
          id: 'gm-1',
          groupId: 'group-1',
          displayName: 'Alex',
          familyMemberId: 'm1',
        ),
        ExpenseGroupMember(
          id: 'gm-2',
          groupId: 'group-1',
          displayName: 'Sam',
          familyMemberId: 'm2',
        ),
      ],
    ),
  ];

  group('ExpenseGroupFields widget', () {
    testWidgets('renders group dropdown and no-group option', (tester) async {
      final amount = TextEditingController(text: '100');
      addTearDown(amount.dispose);

      await pumpTestApp(
        tester,
        overrides: overrides,
        child: Scaffold(
          body: ExpenseGroupFields(
            amountController: amount,
            initialGroupId: 'group-1',
          ),
        ),
      );

      expect(find.text(AppStrings.expenseGroup), findsOneWidget);
      expect(find.text('Trip'), findsWidgets);
      expect(find.text(AppStrings.paidByMember), findsOneWidget);
      expect(find.text(AppStrings.splitType), findsOneWidget);
    });

    testWidgets('shows no group option when groups list is empty', (tester) async {
      final amount = TextEditingController();
      addTearDown(amount.dispose);

      await pumpTestApp(
        tester,
        overrides: [
          expenseGroupsProvider.overrideWith((ref) async => []),
        ],
        child: Scaffold(
          body: ExpenseGroupFields(amountController: amount),
        ),
      );

      expect(find.text(AppStrings.noGroup), findsOneWidget);
    });
  });
}
