import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/pantry/utils/pantry_form_validators.dart';

void main() {
  group('validatePantryQuantity', () {
    test('requires quantity when no availability status', () {
      expect(
        validatePantryQuantity(null, hasAvailabilityStatus: false),
        AppStrings.pantryTrackingRequired,
      );
      expect(
        validatePantryQuantity('  ', hasAvailabilityStatus: false),
        AppStrings.pantryTrackingRequired,
      );
    });

    test('allows empty quantity when availability status is set', () {
      expect(
        validatePantryQuantity(null, hasAvailabilityStatus: true),
        isNull,
      );
      expect(
        validatePantryQuantity('', hasAvailabilityStatus: true),
        isNull,
      );
    });

    test('rejects negative quantity', () {
      expect(
        validatePantryQuantity('-1', hasAvailabilityStatus: false),
        AppStrings.invalidQuantity,
      );
    });

    test('rejects non-numeric quantity', () {
      expect(
        validatePantryQuantity('abc', hasAvailabilityStatus: false),
        AppStrings.invalidQuantity,
      );
    });

    test('accepts zero and positive quantities', () {
      expect(
        validatePantryQuantity('0', hasAvailabilityStatus: false),
        isNull,
      );
      expect(
        validatePantryQuantity('2.5', hasAvailabilityStatus: false),
        isNull,
      );
    });
  });
}
