import '../data/expense_date_filter.dart';

/// Returns the period immediately preceding the one described by [filter],
/// used for month-over-month (or period-over-period) spending comparison.
///
/// - today   -> yesterday
/// - week    -> the same weekday window one week earlier
/// - month   -> the same day-of-month window in the previous calendar month
/// - custom  -> an equal-length window ending the day before the range starts
ExpenseDateRange previousExpenseRange(
  ExpenseDateFilter filter, {
  DateTime? now,
}) {
  final current = filter.rangeFor(now: now);
  switch (filter.preset) {
    case ExpenseDatePreset.today:
      final day = current.start.subtract(const Duration(days: 1));
      return ExpenseDateRange(start: day, end: day);
    case ExpenseDatePreset.week:
      return ExpenseDateRange(
        start: current.start.subtract(const Duration(days: 7)),
        end: current.end.subtract(const Duration(days: 7)),
      );
    case ExpenseDatePreset.month:
      final prevStart =
          DateTime(current.start.year, current.start.month - 1, 1);
      final lastDayPrev =
          DateTime(prevStart.year, prevStart.month + 1, 0).day;
      final day =
          current.end.day <= lastDayPrev ? current.end.day : lastDayPrev;
      final prevEnd = DateTime(prevStart.year, prevStart.month, day);
      return ExpenseDateRange(start: prevStart, end: prevEnd);
    case ExpenseDatePreset.custom:
      final length = current.dayCount;
      final prevEnd = current.start.subtract(const Duration(days: 1));
      final prevStart = prevEnd.subtract(Duration(days: length - 1));
      return ExpenseDateRange(start: prevStart, end: prevEnd);
  }
}

/// Percentage change from [previous] to [current]; null when there is no
/// previous spending to compare against.
double? spendingChangeRatio(double current, double previous) {
  if (previous <= 0) return null;
  return (current - previous) / previous;
}

/// Returns the last [count] periods (oldest first, current last) of the same
/// type as [filter], used to draw the spending-trend comparison chart.
List<ExpenseDateRange> historyExpenseRanges(
  ExpenseDateFilter filter, {
  int count = 7,
  DateTime? now,
}) {
  final current = filter.rangeFor(now: now);
  final ranges = <ExpenseDateRange>[];

  switch (filter.preset) {
    case ExpenseDatePreset.today:
      for (var i = 0; i < count; i++) {
        final day = current.start.subtract(Duration(days: i));
        ranges.add(ExpenseDateRange(start: day, end: day));
      }
    case ExpenseDatePreset.week:
      for (var i = 0; i < count; i++) {
        ranges.add(
          ExpenseDateRange(
            start: current.start.subtract(Duration(days: 7 * i)),
            end: current.end.subtract(Duration(days: 7 * i)),
          ),
        );
      }
    case ExpenseDatePreset.month:
      final baseEndDay = current.end.day;
      for (var i = 0; i < count; i++) {
        final start = DateTime(current.start.year, current.start.month - i, 1);
        final lastDay = DateTime(start.year, start.month + 1, 0).day;
        final day = baseEndDay <= lastDay ? baseEndDay : lastDay;
        ranges.add(
          ExpenseDateRange(
            start: start,
            end: DateTime(start.year, start.month, day),
          ),
        );
      }
    case ExpenseDatePreset.custom:
      final length = current.dayCount;
      for (var i = 0; i < count; i++) {
        ranges.add(
          ExpenseDateRange(
            start: current.start.subtract(Duration(days: length * i)),
            end: current.end.subtract(Duration(days: length * i)),
          ),
        );
      }
  }

  return ranges.reversed.toList();
}
