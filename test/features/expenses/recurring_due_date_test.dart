import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/features/expenses/utils/recurring_due_date.dart';

void main() {
  group('nextMonthlyRecurringDueDate', () {
    test('returns same month when due day is today', () {
      final result = nextMonthlyRecurringDueDate(
        reference: DateTime(2026, 7, 15),
        dayOfMonth: 15,
      );
      expect(result, DateTime(2026, 7, 15));
    });

    test('returns same month when due day is in the future', () {
      final result = nextMonthlyRecurringDueDate(
        reference: DateTime(2026, 7, 8),
        dayOfMonth: 20,
      );
      expect(result, DateTime(2026, 7, 20));
    });

    test('rolls to next month when due day already passed', () {
      final result = nextMonthlyRecurringDueDate(
        reference: DateTime(2026, 7, 20),
        dayOfMonth: 5,
      );
      expect(result, DateTime(2026, 8, 5));
    });

    test('rolls from December to January', () {
      final result = nextMonthlyRecurringDueDate(
        reference: DateTime(2026, 12, 25),
        dayOfMonth: 1,
      );
      expect(result, DateTime(2027, 1, 1));
    });

    test('ignores time-of-day on reference date', () {
      final result = nextMonthlyRecurringDueDate(
        reference: DateTime(2026, 7, 8, 23, 59),
        dayOfMonth: 8,
      );
      expect(result, DateTime(2026, 7, 8));
    });
  });

  group('recurringDayOfMonthForFrequency', () {
    test('returns day for monthly frequency', () {
      expect(recurringDayOfMonthForFrequency('monthly', 15), 15);
    });

    test('returns null for weekly frequency', () {
      expect(recurringDayOfMonthForFrequency('weekly', 15), isNull);
    });

    test('returns null for yearly frequency', () {
      expect(recurringDayOfMonthForFrequency('yearly', 15), isNull);
    });
  });
}
