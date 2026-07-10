import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/constants/meal_slots.dart';

void main() {
  group('MealSlots', () {
    test('isValid accepts known slots', () {
      expect(MealSlots.isValid(MealSlots.breakfast), isTrue);
      expect(MealSlots.isValid(MealSlots.snack), isTrue);
      expect(MealSlots.isValid(null), isFalse);
      expect(MealSlots.isValid('brunch'), isFalse);
    });

    test('labelFor returns label', () {
      expect(MealSlots.labelFor(MealSlots.dinner), 'Dinner');
      expect(MealSlots.labelFor('unknown'), 'Breakfast');
    });

    test('defaultDueAtForSlot sets expected hours', () {
      final breakfast = MealSlots.defaultDueAtForSlot(MealSlots.breakfast);
      expect(breakfast.hour, 8);
      final lunch = MealSlots.defaultDueAtForSlot(MealSlots.lunch);
      expect(lunch.hour, 13);
      final dinner = MealSlots.defaultDueAtForSlot(MealSlots.dinner);
      expect(dinner.hour, 19);
      final snack = MealSlots.defaultDueAtForSlot(MealSlots.snack);
      expect(snack.hour, 16);
    });
  });
}
