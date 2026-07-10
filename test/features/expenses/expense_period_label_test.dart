import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/expenses/data/expense_date_filter.dart';
import 'package:myplanr/features/expenses/utils/expense_period_label.dart';
import 'package:myplanr/shared/utils/formatters.dart';

void main() {
  final reference = DateTime(2026, 7, 8);

  group('expensePeriodLabel', () {
    test('today preset', () {
      const filter = ExpenseDateFilter(preset: ExpenseDatePreset.today);
      expect(expensePeriodLabel(filter), AppStrings.periodToday);
    });

    test('week preset', () {
      const filter = ExpenseDateFilter(preset: ExpenseDatePreset.week);
      expect(expensePeriodLabel(filter), AppStrings.periodThisWeek);
    });

    test('month preset', () {
      const filter = ExpenseDateFilter(preset: ExpenseDatePreset.month);
      expect(expensePeriodLabel(filter), AppStrings.periodThisMonth);
    });

    test('custom preset uses formatted date range', () {
      final filter = ExpenseDateFilter(
        preset: ExpenseDatePreset.custom,
        customStart: DateTime(2026, 1, 1),
        customEnd: DateTime(2026, 1, 31),
      );
      final range = filter.rangeFor(now: reference);
      expect(
        expensePeriodLabel(filter),
        '${Formatters.date(range.start)} – ${Formatters.date(range.end)}',
      );
    });
  });

  group('expensePeriodExportLabel', () {
    test('non-custom presets match expensePeriodLabel', () {
      for (final preset in [
        ExpenseDatePreset.today,
        ExpenseDatePreset.week,
        ExpenseDatePreset.month,
      ]) {
        final filter = ExpenseDateFilter(preset: preset);
        expect(
          expensePeriodExportLabel(filter),
          expensePeriodLabel(filter),
        );
      }
    });

    test('custom preset uses ISO date range', () {
      final filter = ExpenseDateFilter(
        preset: ExpenseDatePreset.custom,
        customStart: DateTime(2026, 3, 1),
        customEnd: DateTime(2026, 3, 15),
      );
      final range = filter.rangeFor(now: reference);
      expect(
        expensePeriodExportLabel(filter),
        '${range.startIso} to ${range.endIso}',
      );
    });
  });
}
