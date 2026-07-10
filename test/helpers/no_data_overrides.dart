import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myplanr/features/expenses/data/expense_repository.dart';
import 'package:myplanr/features/expenses/data/expense_groups_repository.dart';
import 'package:myplanr/features/expenses/data/expenses_list_provider.dart';
import 'package:myplanr/features/expenses/data/recurring_money_rule_repository.dart';
import 'package:myplanr/features/household/data/family_repository.dart';
import 'package:myplanr/features/household/data/household_repository.dart';
import 'package:myplanr/features/household/data/medicine_schedule_repository.dart';
import 'package:myplanr/features/plans/data/plans_list_provider.dart';
import 'package:myplanr/features/reminders/data/reminder_repository.dart';
import 'package:myplanr/shared/models/expense.dart';
import 'package:myplanr/shared/models/household.dart';

import 'dashboard_overrides.dart';
import 'provider_overrides.dart';
import 'stub_notifiers.dart';
import 'stub_repositories.dart';
import 'test_fixtures.dart';

/// Dashboard with every attention/feed provider empty.
List<Override> emptyDashboardOverrides() => [
      ...dashboardTestOverrides(),
      expenseSummaryProvider.overrideWith((ref) async => const []),
      moneySummaryProvider.overrideWith(
        (ref) async => const MoneySummary(
          totalSpent: 0,
          totalEarned: 0,
          netAmount: 0,
        ),
      ),
    ];

/// Expenses tab with no rows, groups, recurring rules, or income.
List<Override> emptyExpensesScreenOverrides() => [
      ...testAuthOverrides,
      expensesListProvider.overrideWith(StubExpensesListNotifier.new),
      moneySummaryProvider.overrideWith(
        (ref) async => const MoneySummary(
          totalSpent: 0,
          totalEarned: 0,
          netAmount: 0,
        ),
      ),
      memberIncomeSummaryProvider.overrideWith((ref) async => []),
      dueRecurringIncomeProvider.overrideWith((ref) async => []),
      dueRecurringExpenseProvider.overrideWith((ref) async => []),
      recurringExpenseRulesProvider.overrideWith((ref) async => []),
      expenseSummaryProvider.overrideWith((ref) async => const []),
      familyRosterProvider.overrideWith((ref) async => []),
      expenseGroupsProvider.overrideWith((ref) async => []),
      recurringMoneyRuleRepositoryProvider.overrideWith(
        (ref) => StubRecurringMoneyRuleRepository(),
      ),
    ];

/// Household screen with no roster, app members, or pending invites.
List<Override> emptyHouseholdOverrides() => [
      ...testAuthOverrides,
      activeHouseholdProvider.overrideWith((ref) async => testHousehold),
      familyRosterProvider.overrideWith((ref) async => []),
      householdMembersProvider.overrideWith((ref) async => []),
      sentPendingInvitesProvider.overrideWith((ref) async => []),
    ];

/// Plans tab with no plans or reminders.
List<Override> emptyPlansScreenOverrides() => [
      ...testAuthOverrides,
      plansListProvider.overrideWith(StubPlansListNotifier.new),
      appRemindersProvider.overrideWith((ref) async => []),
    ];

/// Member detail with no saved details row.
List<Override> emptyFamilyMemberDetailOverrides(String memberId) => [
      ...testAuthOverrides,
      familyMemberProvider(memberId)
          .overrideWith((ref) async => testFamilyMembers.first),
      familyMemberDetailsProvider(memberId).overrideWith((ref) async => null),
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
      memberRecurringIncomeProvider(memberId).overrideWith((ref) async => []),
      medicineSchedulesProvider(memberId).overrideWith((ref) async => []),
    ];
