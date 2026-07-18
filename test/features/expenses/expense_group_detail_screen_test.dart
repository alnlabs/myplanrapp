import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/expenses/data/expense_date_filter.dart';
import 'package:myplanr/features/expenses/data/expense_date_filter_provider.dart';
import 'package:myplanr/features/expenses/data/expense_groups_repository.dart';
import 'package:myplanr/features/expenses/data/expenses_list_provider.dart';
import 'package:myplanr/features/expenses/presentation/expense_group_detail_screen.dart';
import 'package:myplanr/shared/models/expense_group.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/stub_notifiers.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  const groupId = 'group-shared-1';
  final testRange = const ExpenseDateFilter().rangeFor();

  List<Override> sharedOverrides(ExpenseGroup group) {
    return [
      expenseDateRangeProvider.overrideWithValue(testRange),
      expensesListProvider.overrideWith(StubExpensesListNotifier.new),
      expenseGroupProvider(groupId).overrideWith((ref) async => group),
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
      expenseGroupBalancesProvider(groupId)
          .overrideWith((ref) async => testSettlementBalances),
      expenseGroupExpensesProvider.overrideWith(
        () => StubGroupExpensesListNotifier(items: [testGroupExpense]),
      ),
    ];
  }

  group('ExpenseGroupDetailScreen widget', () {
    testWidgets('renders shared group with balances and expenses',
        (tester) async {
      await pumpTestApp(
        tester,
        overrides: sharedOverrides(testSharedExpenseGroup),
        child: const ExpenseGroupDetailScreen(groupId: groupId),
      );

      expect(find.text('Trip to Goa'), findsOneWidget);
      expect(find.text(AppStrings.groupTypeShared), findsOneWidget);
      expect(find.text(AppStrings.netBalance), findsOneWidget);
      expect(find.text('Alice'), findsWidgets);
      expect(find.text('Bob'), findsWidgets);
      expect(find.textContaining('Members:'), findsOneWidget);
      expect(find.text('Dinner'), findsOneWidget);
      expect(find.byTooltip(AppStrings.settlements), findsOneWidget);
    });

    testWidgets('renders organizational group without settlement action',
        (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          expenseDateRangeProvider.overrideWithValue(testRange),
          expensesListProvider.overrideWith(StubExpensesListNotifier.new),
          expenseGroupProvider(groupId)
              .overrideWith((ref) async => testOrgExpenseGroup),
          expenseGroupMembersProvider(groupId).overrideWith(
            (ref) async => const [
              ExpenseGroupMember(
                id: 'gm-a',
                groupId: groupId,
                displayName: 'Alex',
              ),
            ],
          ),
          expenseGroupBalancesProvider(groupId).overrideWith((ref) async => []),
          expenseGroupExpensesProvider
              .overrideWith(StubGroupExpensesListNotifier.new),
        ],
        child: const ExpenseGroupDetailScreen(groupId: groupId),
      );

      expect(find.text('Home repairs'), findsOneWidget);
      expect(find.byTooltip(AppStrings.settlements), findsNothing);
      expect(find.text(AppStrings.emptyExpenses), findsOneWidget);
    });
  });
}
