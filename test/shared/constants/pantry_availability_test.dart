import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/shared/constants/pantry_availability.dart';

void main() {
  group('PantryAvailability.label', () {
    test('maps known statuses', () {
      expect(PantryAvailability.label(PantryAvailability.fine),
          AppStrings.availabilityFine);
      expect(PantryAvailability.label(PantryAvailability.warning),
          AppStrings.availabilityWarning);
      expect(PantryAvailability.label(PantryAvailability.required),
          AppStrings.availabilityRequired);
      expect(PantryAvailability.label(PantryAvailability.emergency),
          AppStrings.availabilityEmergency);
    });

    test('unknown status falls back to auto', () {
      expect(PantryAvailability.label(null), AppStrings.availabilityAuto);
      expect(PantryAvailability.label('unknown'), AppStrings.availabilityAuto);
    });
  });

  group('PantryAvailability.severity', () {
    test('orders emergency highest priority', () {
      expect(
        PantryAvailability.severity(PantryAvailability.emergency),
        lessThan(PantryAvailability.severity(PantryAvailability.warning)),
      );
    });

    test('unknown status has low priority', () {
      expect(PantryAvailability.severity(null), 99);
    });
  });
}
