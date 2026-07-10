import '../../../core/strings/app_strings.dart';
import '../../../shared/utils/formatters.dart';
import '../data/expense_date_filter.dart';

String expensePeriodLabel(ExpenseDateFilter filter) {
  final range = filter.rangeFor();
  return switch (filter.preset) {
    ExpenseDatePreset.today => AppStrings.periodToday,
    ExpenseDatePreset.week => AppStrings.periodThisWeek,
    ExpenseDatePreset.month => AppStrings.periodThisMonth,
    ExpenseDatePreset.custom =>
      '${Formatters.date(range.start)} – ${Formatters.date(range.end)}',
  };
}

String expensePeriodExportLabel(ExpenseDateFilter filter) {
  final range = filter.rangeFor();
  if (filter.preset == ExpenseDatePreset.custom) {
    return '${range.startIso} to ${range.endIso}';
  }
  return expensePeriodLabel(filter);
}
