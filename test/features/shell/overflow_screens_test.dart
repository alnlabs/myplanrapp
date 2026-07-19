import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/auth/data/auth_repository.dart';
import 'package:myplanr/features/expenses/data/expense_repository.dart';
import 'package:myplanr/features/expenses/data/expense_groups_repository.dart';
import 'package:myplanr/features/expenses/data/expenses_list_provider.dart';
import 'package:myplanr/features/expenses/data/recurring_money_rule_repository.dart';
import 'package:myplanr/features/expenses/presentation/expenses_screen.dart';
import 'package:myplanr/features/home/presentation/dashboard_screen.dart';
import 'package:myplanr/features/household/data/family_repository.dart';
import 'package:myplanr/features/household/data/household_repository.dart';
import 'package:myplanr/features/household/data/medicine_schedule_repository.dart';
import 'package:myplanr/features/household/presentation/family_member_detail_screen.dart';
import 'package:myplanr/features/household/presentation/household_screen.dart';
import 'package:myplanr/features/settings/presentation/settings_screen.dart';
import 'package:myplanr/shared/models/expense.dart';
import 'package:myplanr/shared/models/family_member.dart';
import 'package:myplanr/shared/models/household.dart';
import 'package:myplanr/shared/models/user_profile.dart';
import 'package:myplanr/shared/widgets/empty_state.dart';

import '../../helpers/dashboard_overrides.dart';
import '../../helpers/overflow_test_helpers.dart';
import '../../helpers/provider_overrides.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/stub_notifiers.dart';
import '../../helpers/stub_repositories.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  const memberId = 'member-long';

  final longNameMember = const FamilyMember(
    id: memberId,
    householdId: testHouseholdId,
    displayName: testVeryLongDisplayName,
    relationship: 'spouse',
    memberType: 'roster',
    profileDisplayName: testVeryLongDisplayName,
  );

  final longTitleExpense = Expense(
    id: 'exp-long',
    householdId: testHouseholdId,
    categoryId: 'cat-food',
    amount: 99999.99,
    title: testVeryLongExpenseTitle,
    expenseDate: DateTime(2025, 7, 1),
    note: testVeryLongNote,
    paidByMemberName: testVeryLongDisplayName,
  );

  group('Overflow on compact phone width', () {
    testWidgets('dashboard avoids overflow with long greeting content',
        (tester) async {
      useCompactPhoneViewport(tester);

      await expectNoLayoutOverflow(tester, () async {
        await pumpShellTestApp(
          tester,
          overrides: [
            ...dashboardTestOverrides(),
            userProfileProvider.overrideWith(
              (ref) async => const UserProfile(
                id: testUserId,
                displayName: testVeryLongDisplayName,
                activeHouseholdId: testHouseholdId,
              ),
            ),
          ],
          child: const DashboardScreen(),
        );
      });

      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('household member tile avoids overflow with long names',
        (tester) async {
      useCompactPhoneViewport(tester);

      await expectNoLayoutOverflow(tester, () async {
        await pumpTestApp(
          tester,
          overrides: [
            ...testAuthOverrides,
            activeHouseholdProvider.overrideWith((ref) async => testHousehold),
            familyRosterProvider.overrideWith((ref) async => [longNameMember]),
            householdMembersProvider.overrideWith((ref) async => []),
            sentPendingInvitesProvider.overrideWith((ref) async => []),
          ],
          child: const HouseholdScreen(),
        );
      });

      expect(find.textContaining('Alexandersoningtonovich'), findsWidgets);
    });

    testWidgets('family member detail avoids overflow with long values',
        (tester) async {
      useNarrowPhoneViewport(tester);

      await expectNoLayoutOverflow(tester, () async {
        await pumpTestApp(
          tester,
          overrides: [
            ...testAuthOverrides,
            familyMemberProvider(memberId)
                .overrideWith((ref) async => longNameMember),
            familyMemberDetailsProvider(memberId).overrideWith(
              (ref) async => FamilyMemberDetails(
                familyMemberId: memberId,
                householdId: testHouseholdId,
                phone: '9876543210',
                workPlace: testVeryLongExpenseTitle,
                notes: testVeryLongNote,
              ),
            ),
            householdMembersProvider.overrideWith(
              (ref) async => const [
                HouseholdMember(
                  id: 'hm-1',
                  userId: testUserId,
                  role: 'owner',
                  displayName: 'Test User',
                ),
              ],
            ),
            activeHouseholdProvider.overrideWith((ref) async => testHousehold),
            memberIncomeSourceSummaryProvider(memberId)
                .overrideWith((ref) async => []),
            memberRecurringIncomeProvider(memberId)
                .overrideWith((ref) async => []),
            medicineSchedulesProvider(memberId).overrideWith((ref) async => []),
          ],
          child: const FamilyMemberDetailScreen(memberId: memberId),
        );

        await tester.pumpAndSettle();
      });

      expect(find.byType(FamilyMemberDetailScreen), findsOneWidget);
    });

    testWidgets('expenses list avoids overflow with long titles and amounts',
        (tester) async {
      useCompactPhoneViewport(tester);

      await expectNoLayoutOverflow(tester, () async {
        await pumpShellTestApp(
          tester,
          overrides: [
            ...testAuthOverrides,
            expensesListProvider.overrideWith(
              () => StubExpensesListNotifier(items: [longTitleExpense]),
            ),
            moneySummaryProvider.overrideWith((ref) async => testMoneySummary),
            memberIncomeSummaryProvider.overrideWith((ref) async => []),
            dueRecurringIncomeProvider.overrideWith((ref) async => []),
            dueRecurringExpenseProvider.overrideWith((ref) async => []),
            recurringExpenseRulesProvider.overrideWith((ref) async => []),
            expenseSummaryProvider.overrideWith(
              (ref) async => testExpenseSummaryRows,
            ),
            familyRosterProvider.overrideWith((ref) async => testFamilyMembers),
            expenseGroupsProvider.overrideWith((ref) async => []),
          ],
          child: const ExpensesScreen(),
        );
      });

      expect(find.textContaining('Quarterly subscription'), findsOneWidget);
    });

    testWidgets('settings screen scrolls without overflow on narrow width',
        (tester) async {
      useNarrowPhoneViewport(tester);

      await expectNoLayoutOverflow(tester, () async {
        await pumpTestApp(
          tester,
          overrides: [
            ...testAuthOverrides,
            authRepositoryProvider.overrideWith((ref) => StubAuthRepository()),
          ],
          child: const SettingsScreen(),
        );

        await tester.scrollUntilVisible(find.text(AppStrings.signOut), 200);
        await tester.pumpAndSettle();
      });

      expect(find.text(AppStrings.signOut), findsOneWidget);
    });

    testWidgets('EmptyState avoids overflow with very long title and subtitle',
        (tester) async {
      useNarrowPhoneViewport(tester);

      await expectNoLayoutOverflow(tester, () async {
        await pumpTestApp(
          tester,
          child: Scaffold(
            body: EmptyState(
              title: testVeryLongExpenseTitle,
              subtitle: testVeryLongNote,
              actionLabel: AppStrings.addExpense,
              onAction: () {},
            ),
          ),
        );
      });

      expect(find.text(testVeryLongExpenseTitle), findsOneWidget);
    });
  });
}
