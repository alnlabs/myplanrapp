import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/auth/data/auth_repository.dart';
import 'package:myplanr/features/expenses/presentation/expenses_screen.dart';
import 'package:myplanr/features/home/presentation/dashboard_screen.dart';
import 'package:myplanr/features/household/presentation/family_member_detail_screen.dart';
import 'package:myplanr/features/household/presentation/household_screen.dart';
import 'package:myplanr/features/plans/presentation/plans_screen.dart';
import 'package:myplanr/features/settings/presentation/settings_screen.dart';
import 'package:myplanr/shared/providers/record_permissions.dart';
import 'package:myplanr/shared/widgets/empty_state.dart';

import '../../helpers/no_data_overrides.dart';
import '../../helpers/provider_overrides.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/stub_repositories.dart';

void main() {
  const memberId = 'member-1';

  group('No-data screen states', () {
    testWidgets('dashboard shows all-clear attention and zero summaries',
        (tester) async {
      await pumpShellTestApp(
        tester,
        overrides: emptyDashboardOverrides(),
        child: const DashboardScreen(),
      );

      expect(find.text(AppStrings.attentionAllSetTitle), findsOneWidget);
      expect(find.text(AppStrings.attentionAllSetSubtitle), findsOneWidget);
      expect(find.text(AppStrings.noOpenPlans), findsWidgets);
      expect(find.text(AppStrings.monthlyTotal), findsOneWidget);
      expect(find.textContaining('0'), findsWidgets);
    });

    testWidgets('household shows empty family roster with hint', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          ...emptyHouseholdOverrides(),
          isHouseholdOwnerProvider.overrideWith((ref) => true),
        ],
        child: const HouseholdScreen(),
      );

      expect(find.text(AppStrings.emptyFamilyRoster), findsOneWidget);
      expect(find.text(AppStrings.emptyFamilyRosterHint), findsOneWidget);
      expect(find.text(AppStrings.addFamilyMember), findsWidgets);
    });

    testWidgets('expenses screen shows empty state with add action',
        (tester) async {
      await pumpShellTestApp(
        tester,
        overrides: emptyExpensesScreenOverrides(),
        child: const ExpensesScreen(),
      );

      expect(find.text(AppStrings.emptyExpenses), findsOneWidget);
      expect(find.text(AppStrings.emptyExpensesHint), findsOneWidget);
      expect(find.text(AppStrings.addExpense), findsWidgets);
    });

    testWidgets('plans screen shows empty plans state', (tester) async {
      await pumpShellTestApp(
        tester,
        overrides: emptyPlansScreenOverrides(),
        child: const PlansScreen(),
      );

      expect(find.text(AppStrings.emptyTodoRemindersAll), findsOneWidget);
    });

    testWidgets('family member detail renders empty fields when no details',
        (tester) async {
      await pumpTestApp(
        tester,
        overrides: emptyFamilyMemberDetailOverrides(memberId),
        child: const FamilyMemberDetailScreen(memberId: memberId),
      );

      expect(find.text(AppStrings.tabOverview), findsOneWidget);
      expect(find.text(AppStrings.phone), findsWidgets);
      await enterTextByLabel(tester, AppStrings.workPlace, 'Remote Office');
      expect(find.text('Remote Office'), findsOneWidget);
      expect(find.text(AppStrings.bloodGroup), findsNothing);
    });

    testWidgets('settings profile tile falls back to profile title without name',
        (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          ...testAuthOverrides,
          userProfileProvider.overrideWith((ref) async => null),
          authRepositoryProvider.overrideWith((ref) => StubAuthRepository()),
        ],
        child: const SettingsScreen(),
      );

      expect(find.text(AppStrings.profileTitle), findsWidgets);
      expect(find.text(AppStrings.settingsTitle), findsOneWidget);
    });

    testWidgets('EmptyState widget renders title and subtitle only', (tester) async {
      await pumpTestApp(
        tester,
        child: const Scaffold(
          body: EmptyState(
            title: AppStrings.emptyExpenses,
            subtitle: AppStrings.emptyExpensesHint,
          ),
        ),
      );

      expect(find.text(AppStrings.emptyExpenses), findsOneWidget);
      expect(find.text(AppStrings.emptyExpensesHint), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });
  });
}
