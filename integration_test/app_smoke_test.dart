import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/expenses/data/expense_groups_repository.dart';
import 'package:myplanr/features/expenses/data/expenses_list_provider.dart';
import 'package:myplanr/shared/models/expense.dart';
import 'package:myplanr/shared/models/paginated_result.dart';
import 'package:myplanr/features/expenses/data/expense_repository.dart';
import 'package:myplanr/features/expenses/presentation/add_expense_screen.dart';
import 'package:myplanr/features/expenses/presentation/expense_period_filter_bar.dart';
import 'package:myplanr/features/household/data/family_repository.dart';
import 'package:myplanr/features/pantry/presentation/pantry_item_form_screen.dart';

import 'package:myplanr/features/plans/presentation/plan_form_screen.dart';
import 'package:myplanr/features/reminders/presentation/reminder_form_screen.dart';
import 'package:myplanr/features/subscriptions/presentation/subscription_form_screen.dart';
import 'package:myplanr/features/household/data/household_repository.dart';
import 'package:myplanr/features/household/presentation/household_setup_screen.dart';
import 'package:myplanr/features/debug/presentation/logs_screen.dart';
import 'package:myplanr/core/logging/app_logger.dart';

import '../test/helpers/provider_overrides.dart';
import '../test/helpers/stub_repositories.dart';
import '../test/helpers/test_fixtures.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('MyPlanr integration smoke', () {
    testWidgets('expense form validates and period filter renders', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseCategoriesProvider
                .overrideWith((ref) async => testExpenseCategories),
            expenseGroupsProvider.overrideWith((ref) async => []),
            expensesListProvider.overrideWith(_StubExpensesListNotifier.new),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: const [
                  ExpensePeriodFilterBar(),
                  Expanded(child: AddExpenseScreen()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.periodThisMonth), findsWidgets);
      expect(find.text(AppStrings.addExpense), findsOneWidget);

      final save = find.widgetWithText(FilledButton, AppStrings.save);
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.requiredField), findsNWidgets(2));
    });

    testWidgets('pantry form validates required name', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: PantryItemFormScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final save = find.widgetWithText(FilledButton, AppStrings.save);
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.requiredField), findsOneWidget);
    });

    testWidgets('plan and subscription forms render', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...testAuthOverrides,
            familyRosterProvider.overrideWith((ref) async => testFamilyMembers),
          ],
          child: MaterialApp(
            home: DefaultTabController(
              length: 2,
              child: Scaffold(
                appBar: AppBar(
                  bottom: const TabBar(
                    tabs: [
                      Tab(text: 'Plan'),
                      Tab(text: 'Sub'),
                    ],
                  ),
                ),
                body: TabBarView(
                  children: const [
                    PlanFormScreen(),
                    SubscriptionFormScreen(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.addPlan), findsOneWidget);
      await tester.tap(find.text('Sub'));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.addSubscription), findsOneWidget);
    });

    testWidgets('reminder form requires title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: ReminderFormScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final save = find.widgetWithText(FilledButton, AppStrings.save);
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.requiredField), findsOneWidget);
    });

    testWidgets('household setup form renders and validates', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...testAuthOverrides,
            householdRepositoryProvider.overrideWith(
              (ref) => StubHouseholdRepository(),
            ),
          ],
          child: const MaterialApp(home: HouseholdSetupScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.noHousehold), findsOneWidget);

      final create = find.widgetWithText(FilledButton, AppStrings.createHousehold);
      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.requiredField), findsOneWidget);
    });

    testWidgets('logs screen renders captured entries', (tester) async {
      AppLogger.instance.entries.value = [
        LogEntry(
          time: DateTime(2025, 1, 1),
          level: LogLevel.info,
          message: 'Integration smoke log',
        ),
      ];
      addTearDown(() => AppLogger.instance.entries.value = []);

      await tester.pumpWidget(
        const MaterialApp(home: LogsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Integration smoke log'), findsOneWidget);
    });
  });
}

class _StubExpensesListNotifier extends ExpensesListNotifier {
  @override
  Future<String?> get householdId async => null;

  @override
  Future<PaginatedResult<Expense>> fetchPage(
    String householdId,
    int offset,
    int limit,
  ) async {
    return const PaginatedResult(items: [], hasMore: false);
  }
}
