import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/household/utils/medicine_form_validators.dart';
import 'package:myplanr/shared/constants/medicine_constants.dart';
import 'package:myplanr/shared/models/medicine_schedule.dart';

import '../../helpers/test_fixtures.dart';

void main() {
  group('resolveMedicinePurpose', () {
    test('uses predefined purpose directly', () {
      expect(
        resolveMedicinePurpose(
          selectedPurpose: 'Diabetes',
          customPurposeText: '',
        ),
        'Diabetes',
      );
    });

    test('uses custom text when Other is selected', () {
      expect(
        resolveMedicinePurpose(
          selectedPurpose: MedicinePurposes.other,
          customPurposeText: '  Custom med  ',
        ),
        'Custom med',
      );
    });
  });

  group('validateMedicinePurpose', () {
    test('rejects empty purpose', () {
      expect(
        validateMedicinePurpose(
          selectedPurpose: null,
          customPurposeText: '',
        ),
        AppStrings.medicineForRequired,
      );
    });

    test('rejects empty custom purpose for Other', () {
      expect(
        validateMedicinePurpose(
          selectedPurpose: MedicinePurposes.other,
          customPurposeText: '  ',
        ),
        AppStrings.medicineForRequired,
      );
    });

    test('accepts predefined purpose', () {
      expect(
        validateMedicinePurpose(
          selectedPurpose: 'Heart',
          customPurposeText: '',
        ),
        isNull,
      );
    });
  });

  group('validateMedicineTimes', () {
    test('requires at least one time', () {
      expect(validateMedicineTimes(0), AppStrings.timesPerDayHint);
    });

    test('accepts one or more times', () {
      expect(validateMedicineTimes(2), isNull);
    });
  });

  group('initialMedicinePurposeSelection', () {
    test('returns predefined purpose for known schedule', () {
      expect(
        initialMedicinePurposeSelection(testMedicineSchedule),
        'Blood pressure',
      );
    });

    test('returns Other for custom schedule purpose', () {
      const schedule = MedicineSchedule(
        id: 'med-2',
        familyMemberId: 'member-1',
        householdId: testHouseholdId,
        medicineFor: 'Custom condition',
      );
      expect(initialMedicinePurposeSelection(schedule), MedicinePurposes.other);
    });

    test('returns null for new schedule', () {
      expect(initialMedicinePurposeSelection(null), isNull);
    });
  });

  group('initialMedicineCustomPurpose', () {
    test('returns custom text for non-predefined purpose', () {
      const schedule = MedicineSchedule(
        id: 'med-2',
        familyMemberId: 'member-1',
        householdId: testHouseholdId,
        medicineFor: 'Custom condition',
      );
      expect(initialMedicineCustomPurpose(schedule), 'Custom condition');
    });

    test('returns empty for predefined purpose', () {
      expect(initialMedicineCustomPurpose(testMedicineSchedule), '');
    });
  });
}
