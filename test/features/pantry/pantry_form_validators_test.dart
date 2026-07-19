import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/pantry/utils/pantry_form_validators.dart';

void main() {
  group('validatePantryQuantity', () {
    test('quantity is optional (independent of availability label)', () {
      expect(validatePantryQuantity(null), isNull);
      expect(validatePantryQuantity(''), isNull);
      expect(validatePantryQuantity('  '), isNull);
    });

    test('rejects negative quantity', () {
      expect(validatePantryQuantity('-1'), AppStrings.invalidQuantity);
    });

    test('rejects non-numeric quantity', () {
      expect(validatePantryQuantity('abc'), AppStrings.invalidQuantity);
    });

    test('accepts zero and positive quantities', () {
      expect(validatePantryQuantity('0'), isNull);
      expect(validatePantryQuantity('2.5'), isNull);
    });
  });
}
