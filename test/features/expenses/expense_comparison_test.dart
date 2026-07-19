import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/features/expenses/data/expense_date_filter.dart';
import 'package:myplanr/features/expenses/utils/expense_comparison.dart';

void main() {
  group('previousExpenseRange', () {
    test('month preset maps to same day-of-month window last month', () {
      const filter = ExpenseDateFilter(preset: ExpenseDatePreset.month);
      final now = DateTime(2026, 7, 19);
      final prev = previousExpenseRange(filter, now: now);
      expect(prev.start, DateTime(2026, 6, 1));
      expect(prev.end, DateTime(2026, 6, 19));
    });

    test('month preset clamps to last day of shorter previous month', () {
      const filter = ExpenseDateFilter(preset: ExpenseDatePreset.month);
      final now = DateTime(2026, 3, 31);
      final prev = previousExpenseRange(filter, now: now);
      expect(prev.start, DateTime(2026, 2, 1));
      expect(prev.end, DateTime(2026, 2, 28));
    });

    test('month preset crosses year boundary', () {
      const filter = ExpenseDateFilter(preset: ExpenseDatePreset.month);
      final now = DateTime(2026, 1, 15);
      final prev = previousExpenseRange(filter, now: now);
      expect(prev.start, DateTime(2025, 12, 1));
      expect(prev.end, DateTime(2025, 12, 15));
    });

    test('week preset shifts back seven days', () {
      const filter = ExpenseDateFilter(preset: ExpenseDatePreset.week);
      final now = DateTime(2026, 7, 15); // Wednesday
      final current = filter.rangeFor(now: now);
      final prev = previousExpenseRange(filter, now: now);
      expect(prev.start, current.start.subtract(const Duration(days: 7)));
      expect(prev.end, current.end.subtract(const Duration(days: 7)));
    });

    test('today preset maps to yesterday', () {
      const filter = ExpenseDateFilter(preset: ExpenseDatePreset.today);
      final now = DateTime(2026, 7, 19);
      final prev = previousExpenseRange(filter, now: now);
      expect(prev.start, DateTime(2026, 7, 18));
      expect(prev.end, DateTime(2026, 7, 18));
    });

    test('custom preset maps to equal-length preceding window', () {
      final filter = ExpenseDateFilter(
        preset: ExpenseDatePreset.custom,
        customStart: DateTime(2026, 7, 10),
        customEnd: DateTime(2026, 7, 19), // 10 days
      );
      final prev = previousExpenseRange(filter);
      expect(prev.end, DateTime(2026, 7, 9));
      expect(prev.start, DateTime(2026, 6, 30));
    });
  });

  group('historyExpenseRanges', () {
    test('returns 7 month windows oldest-first ending with current', () {
      const filter = ExpenseDateFilter(preset: ExpenseDatePreset.month);
      final now = DateTime(2026, 7, 19);
      final ranges = historyExpenseRanges(filter, now: now);
      expect(ranges.length, 7);
      expect(ranges.first.start, DateTime(2026, 1, 1));
      expect(ranges.last.start, DateTime(2026, 7, 1));
      expect(ranges.last.end, DateTime(2026, 7, 19));
    });

    test('day view returns 7 consecutive days ending today', () {
      const filter = ExpenseDateFilter(preset: ExpenseDatePreset.today);
      final now = DateTime(2026, 7, 19);
      final ranges = historyExpenseRanges(filter, now: now);
      expect(ranges.length, 7);
      expect(ranges.first.start, DateTime(2026, 7, 13));
      expect(ranges.last.start, DateTime(2026, 7, 19));
    });

    test('custom view steps back by the range length', () {
      final filter = ExpenseDateFilter(
        preset: ExpenseDatePreset.custom,
        customStart: DateTime(2026, 7, 15),
        customEnd: DateTime(2026, 7, 19), // 5 days
      );
      final ranges = historyExpenseRanges(filter);
      expect(ranges.length, 7);
      expect(ranges.last.start, DateTime(2026, 7, 15));
      expect(ranges.last.end, DateTime(2026, 7, 19));
      // Second to last is the preceding 5-day window.
      expect(ranges[5].start, DateTime(2026, 7, 10));
      expect(ranges[5].end, DateTime(2026, 7, 14));
    });
  });

  group('spendingChangeRatio', () {
    test('returns null when previous is zero', () {
      expect(spendingChangeRatio(100, 0), isNull);
    });

    test('computes positive and negative changes', () {
      expect(spendingChangeRatio(150, 100), closeTo(0.5, 1e-9));
      expect(spendingChangeRatio(80, 100), closeTo(-0.2, 1e-9));
    });
  });
}
