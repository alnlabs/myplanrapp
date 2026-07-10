import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/household/data/medicine_schedule_repository.dart';
import 'package:myplanr/features/household/presentation/medicine_schedules_section.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  const memberId = 'member-1';

  group('MedicineSchedulesSection widget', () {
    testWidgets('renders schedules and add button when editable', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          medicineSchedulesProvider(memberId).overrideWith(
            (ref) async => [testMedicineSchedule],
          ),
        ],
        child: const MedicineSchedulesSection(
          familyMemberId: memberId,
          householdId: testHouseholdId,
          canEdit: true,
        ),
      );

      expect(find.text(AppStrings.medicineSchedules), findsOneWidget);
      expect(find.text(AppStrings.add), findsOneWidget);
      expect(find.text('Blood pressure'), findsOneWidget);
      expect(find.textContaining('Amlodipine'), findsOneWidget);
      expect(find.textContaining('08:00'), findsOneWidget);
    });

    testWidgets('shows empty message when no schedules', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          medicineSchedulesProvider(memberId).overrideWith((ref) async => []),
        ],
        child: const MedicineSchedulesSection(
          familyMemberId: memberId,
          householdId: testHouseholdId,
          canEdit: true,
        ),
      );

      expect(find.text(AppStrings.noMedicineSchedules), findsOneWidget);
    });

    testWidgets('hides add button when not editable', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          medicineSchedulesProvider(memberId).overrideWith(
            (ref) async => [testMedicineSchedule],
          ),
        ],
        child: const MedicineSchedulesSection(
          familyMemberId: memberId,
          householdId: testHouseholdId,
          canEdit: false,
        ),
      );

      expect(find.text(AppStrings.add), findsNothing);
      expect(find.text('Blood pressure'), findsOneWidget);
    });
  });
}
