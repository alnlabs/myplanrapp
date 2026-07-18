import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/expenses/data/expense_repository.dart';
import 'package:myplanr/features/expenses/data/recurring_money_rule_repository.dart';
import 'package:myplanr/features/household/data/family_repository.dart';
import 'package:myplanr/features/household/data/household_repository.dart';
import 'package:myplanr/features/household/data/medicine_schedule_repository.dart';
import 'package:myplanr/features/household/presentation/family_member_detail_screen.dart';
import 'package:myplanr/features/household/presentation/household_screen.dart';

import '../../helpers/provider_overrides.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  const memberId = 'member-1';

  group('HouseholdScreen widget', () {
    testWidgets('renders household header and members section', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          ...testAuthOverrides,
          activeHouseholdProvider.overrideWith((ref) async => testHousehold),
          familyRosterProvider.overrideWith((ref) async => testFamilyMembers),
          householdMembersProvider.overrideWith((ref) async => []),
          sentPendingInvitesProvider.overrideWith((ref) async => []),
        ],
        child: const HouseholdScreen(),
      );

      expect(find.text(AppStrings.householdTitle), findsWidgets);
      expect(find.text(AppStrings.membersAndRoles), findsOneWidget);
      expect(find.textContaining('Alex'), findsWidgets);
    });
  });

  group('FamilyMemberDetailScreen widget', () {
    testWidgets('renders member header and read-only details', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          ...testAuthOverrides,
          familyMemberProvider(memberId)
              .overrideWith((ref) async => testFamilyMembers.first),
          familyMemberDetailsProvider(memberId)
              .overrideWith((ref) async => testFamilyMemberDetails),
          householdMembersProvider.overrideWith((ref) async => []),
          activeHouseholdProvider.overrideWith((ref) async => testHousehold),
          memberIncomeSourceSummaryProvider(memberId)
              .overrideWith((ref) async => []),
          memberRecurringIncomeProvider(memberId)
              .overrideWith((ref) async => []),
          medicineSchedulesProvider(memberId).overrideWith((ref) async => []),
        ],
        child: const FamilyMemberDetailScreen(memberId: memberId),
      );

      expect(find.textContaining('Alex'), findsWidgets);
      expect(find.text(AppStrings.sectionContact), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);
    });
  });
}
