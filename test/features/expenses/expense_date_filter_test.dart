import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/features/expenses/data/expense_date_filter.dart';

void main() {
  final wednesday = DateTime(2026, 7, 8); // Wednesday

  group('ExpenseDatePreset.today', () {
    test('start and end are the same day', () {
      const filter = ExpenseDateFilter(preset: ExpenseDatePreset.today);
      final range = filter.rangeFor(now: wednesday);
      expect(range.start, DateTime(2026, 7, 8));
      expect(range.end, DateTime(2026, 7, 8));
      expect(range.dayCount, 1);
    });
  });

  group('ExpenseDatePreset.week', () {
    test('starts on Monday of current week', () {
      const filter = ExpenseDateFilter(preset: ExpenseDatePreset.week);
      final range = filter.rangeFor(now: wednesday);
      expect(range.start, DateTime(2026, 7, 6)); // Monday
      expect(range.end, DateTime(2026, 7, 8));
      expect(range.dayCount, 3);
    });

    test('when today is Monday, range is one day', () {
      const filter = ExpenseDateFilter(preset: ExpenseDatePreset.week);
      final monday = DateTime(2026, 7, 6);
      final range = filter.rangeFor(now: monday);
      expect(range.start, monday);
      expect(range.end, monday);
      expect(range.dayCount, 1);
    });
  });

  group('ExpenseDatePreset.month', () {
    test('starts on first of month through today', () {
      const filter = ExpenseDateFilter(preset: ExpenseDatePreset.month);
      final range = filter.rangeFor(now: wednesday);
      expect(range.start, DateTime(2026, 7, 1));
      expect(range.end, DateTime(2026, 7, 8));
      expect(range.dayCount, 8);
    });
  });

  group('ExpenseDatePreset.custom', () {
    test('uses explicit custom start and end', () {
      final filter = ExpenseDateFilter(
        preset: ExpenseDatePreset.custom,
        customStart: DateTime(2026, 1, 1),
        customEnd: DateTime(2026, 1, 31),
      );
      final range = filter.rangeFor(now: wednesday);
      expect(range.start, DateTime(2026, 1, 1));
      expect(range.end, DateTime(2026, 1, 31));
      expect(range.dayCount, 31);
    });

    test('falls back to today when custom dates are null', () {
      const filter = ExpenseDateFilter(preset: ExpenseDatePreset.custom);
      final range = filter.rangeFor(now: wednesday);
      expect(range.start, DateTime(2026, 7, 8));
      expect(range.end, DateTime(2026, 7, 8));
    });
  });

  group('ExpenseDateRange', () {
    test('toIsoDate strips time component', () {
      expect(
        ExpenseDateRange.toIsoDate(DateTime(2026, 7, 8, 15, 30)),
        '2026-07-08',
      );
    });

    test('startIso and endIso match formatted dates', () {
      final range = ExpenseDateRange(
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 15),
      );
      expect(range.startIso, '2026-03-01');
      expect(range.endIso, '2026-03-15');
    });
  });

  group('isValidCustomRange', () {
    test('accepts same-day range', () {
      final day = DateTime(2026, 7, 8);
      expect(ExpenseDateFilter.isValidCustomRange(day, day), isTrue);
    });

    test('accepts range exactly 366 days', () {
      final start = DateTime(2025, 1, 1);
      final end = start.add(const Duration(days: 365));
      expect(ExpenseDateFilter.isValidCustomRange(start, end), isTrue);
    });

    test('rejects end before start', () {
      expect(
        ExpenseDateFilter.isValidCustomRange(
          DateTime(2026, 7, 10),
          DateTime(2026, 7, 9),
        ),
        isFalse,
      );
    });

    test('rejects range longer than 366 days', () {
      final start = DateTime(2025, 1, 1);
      final end = start.add(const Duration(days: 366));
      expect(ExpenseDateFilter.isValidCustomRange(start, end), isFalse);
    });
  });

  group('customRangeError', () {
    const filter = ExpenseDateFilter(preset: ExpenseDatePreset.custom);

    test('returns null for valid range', () {
      expect(
        filter.customRangeError(DateTime(2026, 1, 1), DateTime(2026, 1, 31)),
        isNull,
      );
    });

    test('returns message when end is before start', () {
      expect(
        filter.customRangeError(DateTime(2026, 7, 10), DateTime(2026, 7, 9)),
        'End date must be on or after start date',
      );
    });

    test('returns message when range exceeds 366 days', () {
      final start = DateTime(2025, 1, 1);
      final end = start.add(const Duration(days: 366));
      expect(
        filter.customRangeError(start, end),
        'Range cannot exceed 366 days',
      );
    });
  });

  group('copyWith', () {
    test('updates preset while keeping custom dates', () {
      const original = ExpenseDateFilter(
        preset: ExpenseDatePreset.month,
      );
      final updated = original.copyWith(
        preset: ExpenseDatePreset.custom,
        customStart: DateTime(2026, 1, 1),
        customEnd: DateTime(2026, 1, 31),
      );
      expect(updated.preset, ExpenseDatePreset.custom);
      expect(updated.customStart, DateTime(2026, 1, 1));
      expect(updated.customEnd, DateTime(2026, 1, 31));
    });

    test('updates custom dates', () {
      const original = ExpenseDateFilter(preset: ExpenseDatePreset.custom);
      final updated = original.copyWith(
        customStart: DateTime(2026, 2, 1),
        customEnd: DateTime(2026, 2, 28),
      );
      expect(updated.customStart, DateTime(2026, 2, 1));
      expect(updated.customEnd, DateTime(2026, 2, 28));
    });
  });

  group('defaults', () {
    test('default preset is month', () {
      const filter = ExpenseDateFilter();
      expect(filter.preset, ExpenseDatePreset.month);
      expect(filter.customStart, isNull);
      expect(filter.customEnd, isNull);
    });

    test('maxCustomRangeDays is 366', () {
      expect(ExpenseDateFilter.maxCustomRangeDays, 366);
    });
  });
}
