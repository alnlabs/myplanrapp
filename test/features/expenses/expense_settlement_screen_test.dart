import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/expenses/data/expense_groups_repository.dart';
import 'package:myplanr/features/expenses/presentation/expense_settlement_screen.dart';
import 'package:myplanr/shared/models/expense_group.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/stub_repositories.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  const groupId = 'group-settle-1';
  late StubExpenseGroupsRepository groupsRepo;

  List<Override> overrides() => [
        expenseGroupBalancesProvider(groupId)
            .overrideWith((ref) async => testSettlementBalances),
        expenseGroupMembersProvider(groupId).overrideWith(
          (ref) async => const [
            ExpenseGroupMember(
              id: 'gm-a',
              groupId: groupId,
              displayName: 'Alice',
            ),
            ExpenseGroupMember(
              id: 'gm-b',
              groupId: groupId,
              displayName: 'Bob',
            ),
          ],
        ),
        expenseGroupsRepositoryProvider.overrideWithValue(groupsRepo),
      ];

  setUp(() {
    groupsRepo = StubExpenseGroupsRepository();
  });

  group('ExpenseSettlementScreen widget', () {
    testWidgets('renders balances and suggested settlement', (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides(),
        child: const ExpenseSettlementScreen(groupId: groupId),
      );

      expect(find.text(AppStrings.settlements), findsOneWidget);
      expect(find.text(AppStrings.netBalance), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text(AppStrings.suggestedSettlements), findsOneWidget);
      expect(find.text('Bob → Alice'), findsOneWidget);
      expect(find.text(AppStrings.recordSettlement), findsOneWidget);
    });

    testWidgets('shows empty suggestions when all settled', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          expenseGroupBalancesProvider(groupId).overrideWith(
            (ref) async => const [
              ExpenseGroupBalance(
                groupMemberId: 'gm-a',
                displayName: 'Alice',
                paidTotal: 50,
                owedTotal: 50,
                settledIn: 0,
                settledOut: 0,
                netBalance: 0,
              ),
            ],
          ),
          expenseGroupMembersProvider(groupId).overrideWith(
            (ref) async => const [
              ExpenseGroupMember(
                id: 'gm-a',
                groupId: groupId,
                displayName: 'Alice',
              ),
            ],
          ),
        ],
        child: const ExpenseSettlementScreen(groupId: groupId),
      );

      expect(find.text(AppStrings.emptyExpenses), findsOneWidget);
    });

    testWidgets('records suggested settlement when amount tapped', (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides(),
        child: const ExpenseSettlementScreen(groupId: groupId),
      );

      await tester.tap(find.textContaining('₹').last);
      await tester.pumpAndSettle();

      expect(groupsRepo.recordSettlementCalls, 1);
      expect(groupsRepo.lastGroupId, groupId);
      expect(groupsRepo.lastFromMemberId, 'gm-b');
      expect(groupsRepo.lastToMemberId, 'gm-a');
      expect(groupsRepo.lastAmount, 50);
      expect(find.text(AppStrings.saved), findsOneWidget);
    });

    testWidgets('manual settlement dialog saves amount and note', (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides(),
        child: const ExpenseSettlementScreen(groupId: groupId),
      );

      await tester.tap(find.text(AppStrings.recordSettlement).last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bob').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alice').last);
      await tester.pumpAndSettle();

      await enterTextByLabel(tester, AppStrings.amount, '25');
      await enterTextByLabel(tester, AppStrings.note, 'Cash handoff');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, AppStrings.save));
      await tester.pumpAndSettle();

      expect(groupsRepo.recordSettlementCalls, 1);
      expect(groupsRepo.lastAmount, 25);
      expect(groupsRepo.lastNote, 'Cash handoff');
      expect(find.text(AppStrings.saved), findsOneWidget);
    });
  });
}
