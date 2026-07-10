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
import 'package:myplanr/shared/models/family_member.dart';
import 'package:myplanr/shared/models/household.dart';

import '../../helpers/provider_overrides.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/stub_repositories.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  const memberId = 'member-1';

  late StubFamilyRepository familyRepo;

  List<Override> detailOverrides() => [
        ...testAuthOverrides,
        familyRepositoryProvider.overrideWithValue(familyRepo),
        familyMemberProvider(memberId)
            .overrideWith((ref) async => testFamilyMembers.first),
        familyMemberDetailsProvider(memberId)
            .overrideWith((ref) async => testFamilyMemberDetails),
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

  setUp(() {
    familyRepo = StubFamilyRepository();
  });

  group('FamilyMemberDetailScreen behavior', () {
    testWidgets('overview tab edits all contact and clothing fields then saves',
        (tester) async {
      await pumpTestApp(
        tester,
        overrides: detailOverrides(),
        child: const FamilyMemberDetailScreen(memberId: memberId),
      );

      await enterTextByLabel(tester, AppStrings.phone, '9000000001');
      await enterTextByLabel(tester, AppStrings.altPhone, '9000000002');
      await enterTextByLabel(tester, AppStrings.workPlace, 'Acme Labs');
      await enterTextByLabel(tester, AppStrings.schoolName, 'Springfield High');
      await enterTextByLabel(tester, AppStrings.shirtSize, 'L');
      await enterTextByLabel(tester, AppStrings.pantsSize, '32');
      await enterTextByLabel(tester, AppStrings.shoeSize, '10');

      await tester.ensureVisible(find.text(AppStrings.visibilityHealth));
      await tester.tap(find.widgetWithText(SwitchListTile, AppStrings.visibilityHealth));
      await tester.pumpAndSettle();

            await tapSave(tester);

      expect(find.text(AppStrings.saved), findsOneWidget);
      expect(familyRepo.lastUpsertedMemberId, memberId);
      expect(familyRepo.lastUpsertedDetails?.phone, '9000000001');
      expect(familyRepo.lastUpsertedDetails?.altPhone, '9000000002');
      expect(familyRepo.lastUpsertedDetails?.workPlace, 'Acme Labs');
      expect(familyRepo.lastUpsertedDetails?.schoolName, 'Springfield High');
      expect(
        familyRepo.lastUpsertedDetails?.clothingSizes[ClothingSizeKeys.shirt],
        'L',
      );
      expect(
        familyRepo.lastUpsertedDetails?.clothingSizes[ClothingSizeKeys.pants],
        '32',
      );
      expect(
        familyRepo.lastUpsertedDetails?.clothingSizes[ClothingSizeKeys.shoes],
        '10',
      );
      expect(
        familyRepo.lastUpsertedDetails?.visibility[MemberVisibilityKeys.health],
        false,
      );
    });

    testWidgets('health tab edits medical fields and diet then saves',
        (tester) async {
      await pumpTestApp(
        tester,
        overrides: detailOverrides(),
        child: const FamilyMemberDetailScreen(memberId: memberId),
      );

      await tester.tap(find.text(AppStrings.tabHealth));
      await tester.pumpAndSettle();

      await enterTextByLabel(tester, AppStrings.bloodGroup, 'A+');
      await enterTextByLabel(tester, AppStrings.allergies, 'Pollen');
      await enterTextByLabel(tester, AppStrings.medicines, 'Vitamin D');
      await enterTextByLabel(tester, AppStrings.doctorName, 'Dr. Rao');
      await enterTextByLabel(tester, AppStrings.doctorPhone, '9111111111');
      await enterTextByLabel(tester, AppStrings.foodAllergies, 'Peanuts');

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vegetarian').last);
      await tester.pumpAndSettle();

      await tapSave(tester);

      expect(find.text(AppStrings.saved), findsOneWidget);
      expect(familyRepo.lastUpsertedDetails?.bloodGroup, 'A+');
      expect(familyRepo.lastUpsertedDetails?.allergies, 'Pollen');
      expect(familyRepo.lastUpsertedDetails?.medicines, 'Vitamin D');
      expect(familyRepo.lastUpsertedDetails?.doctorName, 'Dr. Rao');
      expect(familyRepo.lastUpsertedDetails?.doctorPhone, '9111111111');
      expect(familyRepo.lastUpsertedDetails?.foodAllergies, 'Peanuts');
      expect(familyRepo.lastUpsertedDetails?.dietaryPreference, 'veg');
    });

    testWidgets('emergency tab edits all emergency fields then saves',
        (tester) async {
      await pumpTestApp(
        tester,
        overrides: detailOverrides(),
        child: const FamilyMemberDetailScreen(memberId: memberId),
      );

      await tester.tap(find.text(AppStrings.tabEmergency));
      await tester.pumpAndSettle();

      await enterTextByLabel(
        tester,
        AppStrings.emergencyContactName,
        'Jordan',
      );
      await enterTextByLabel(
        tester,
        AppStrings.emergencyContactPhone,
        '9222222222',
      );
      await enterTextByLabel(
        tester,
        AppStrings.emergencyContactRelation,
        'Sibling',
      );
      await enterTextByLabel(tester, AppStrings.notes, 'Call after 6pm');

      await tapSave(tester);

      expect(find.text(AppStrings.saved), findsOneWidget);
      expect(familyRepo.lastUpsertedDetails?.emergencyContactName, 'Jordan');
      expect(familyRepo.lastUpsertedDetails?.emergencyContactPhone, '9222222222');
      expect(
        familyRepo.lastUpsertedDetails?.emergencyContactRelation,
        'Sibling',
      );
      expect(familyRepo.lastUpsertedDetails?.notes, 'Call after 6pm');
    });

    testWidgets('switching tabs preserves unsaved overview field values',
        (tester) async {
      await pumpTestApp(
        tester,
        overrides: detailOverrides(),
        child: const FamilyMemberDetailScreen(memberId: memberId),
      );

      await enterTextByLabel(tester, AppStrings.workPlace, 'Remote Office');
      await tester.tap(find.text(AppStrings.tabHealth));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.tabOverview));
      await tester.pumpAndSettle();

      expect(find.text('Remote Office'), findsOneWidget);
    });
  });
}
