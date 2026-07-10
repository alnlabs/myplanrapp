import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/shared/utils/validators.dart';

void main() {
  group('Validators.required', () {
    test('rejects null', () {
      expect(Validators.required(null), AppStrings.requiredField);
    });

    test('rejects empty string', () {
      expect(Validators.required(''), AppStrings.requiredField);
    });

    test('rejects whitespace only', () {
      expect(Validators.required('   '), AppStrings.requiredField);
    });

    test('accepts non-empty trimmed value', () {
      expect(Validators.required('Rent'), isNull);
      expect(Validators.required('  Groceries  '), isNull);
    });
  });

  group('Validators.category', () {
    test('rejects null', () {
      expect(Validators.category(null), AppStrings.selectCategory);
    });

    test('rejects empty string', () {
      expect(Validators.category(''), AppStrings.selectCategory);
    });

    test('accepts category id', () {
      expect(Validators.category('cat-uuid-1'), isNull);
    });
  });

  group('Validators.positiveAmount', () {
    test('rejects null and empty', () {
      expect(Validators.positiveAmount(null), AppStrings.requiredField);
      expect(Validators.positiveAmount(''), AppStrings.requiredField);
      expect(Validators.positiveAmount('   '), AppStrings.requiredField);
    });

    test('rejects zero and negative values', () {
      expect(Validators.positiveAmount('0'), AppStrings.invalidAmount);
      expect(Validators.positiveAmount('-5'), AppStrings.invalidAmount);
    });

    test('rejects non-numeric values', () {
      expect(Validators.positiveAmount('abc'), AppStrings.invalidAmount);
    });

    test('accepts positive integers and decimals', () {
      expect(Validators.positiveAmount('1'), isNull);
      expect(Validators.positiveAmount('99.99'), isNull);
      expect(Validators.positiveAmount('  42.5  '), isNull);
    });
  });

  group('Validators.positiveNumber', () {
    test('rejects null and empty', () {
      expect(Validators.positiveNumber(null), AppStrings.requiredField);
      expect(Validators.positiveNumber(''), AppStrings.requiredField);
    });

    test('rejects negative values', () {
      expect(Validators.positiveNumber('-1'), AppStrings.invalidQuantity);
    });

    test('accepts zero', () {
      expect(Validators.positiveNumber('0'), isNull);
    });

    test('accepts positive values', () {
      expect(Validators.positiveNumber('50'), isNull);
      expect(Validators.positiveNumber('33.33'), isNull);
    });

    test('uses custom message when provided', () {
      expect(
        Validators.positiveNumber('-1', message: 'Custom error'),
        'Custom error',
      );
    });
  });
}
