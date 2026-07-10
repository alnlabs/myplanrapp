import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/constants/pantry_constants.dart';

void main() {
  group('PantryUnits.family', () {
    test('groups mass units', () {
      expect(PantryUnits.family('g'), 'mass');
      expect(PantryUnits.family('kg'), 'mass');
    });

    test('groups volume units', () {
      expect(PantryUnits.family('ml'), 'volume');
      expect(PantryUnits.family('L'), 'volume');
    });

    test('treats count units separately', () {
      expect(PantryUnits.family('pcs'), 'count');
      expect(PantryUnits.family('pack'), 'count');
    });
  });

  group('PantryUnits.compatibleWith', () {
    test('returns same-family units only', () {
      expect(PantryUnits.compatibleWith('kg'), ['g', 'kg']);
      expect(PantryUnits.compatibleWith('ml'), ['ml', 'L']);
    });
  });

  group('PantryUnits.baseFactor', () {
    test('converts kg and L to base units', () {
      expect(PantryUnits.baseFactor('kg'), 1000);
      expect(PantryUnits.baseFactor('L'), 1000);
      expect(PantryUnits.baseFactor('g'), 1);
    });
  });

  group('PantryUnits labels', () {
    test('label returns short form', () {
      expect(PantryUnits.label('kg'), 'kg');
    });

    test('displayLabel returns descriptive text', () {
      expect(PantryUnits.displayLabel('kg'), contains('kilograms'));
    });

    test('unknown unit passes through', () {
      expect(PantryUnits.label('box'), 'box');
    });
  });
}
