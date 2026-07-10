enum ExpenseDatePreset {
  today,
  week,
  month,
  custom,
}

class ExpenseDateRange {
  const ExpenseDateRange({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;

  int get dayCount => end.difference(start).inDays + 1;

  String get startIso => toIsoDate(start);
  String get endIso => toIsoDate(end);

  static String toIsoDate(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    return local.toIso8601String().split('T').first;
  }
}

class ExpenseDateFilter {
  const ExpenseDateFilter({
    this.preset = ExpenseDatePreset.month,
    this.customStart,
    this.customEnd,
  });

  static const maxCustomRangeDays = 366;

  final ExpenseDatePreset preset;
  final DateTime? customStart;
  final DateTime? customEnd;

  ExpenseDateRange rangeFor({DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    return switch (preset) {
      ExpenseDatePreset.today => ExpenseDateRange(start: today, end: today),
      ExpenseDatePreset.week => ExpenseDateRange(
          start: today.subtract(Duration(days: today.weekday - 1)),
          end: today,
        ),
      ExpenseDatePreset.month => ExpenseDateRange(
          start: DateTime(today.year, today.month, 1),
          end: today,
        ),
      ExpenseDatePreset.custom => ExpenseDateRange(
          start: _dateOnly(customStart ?? today),
          end: _dateOnly(customEnd ?? today),
        ),
    };
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool isValidCustomRange(DateTime start, DateTime end) {
    final s = _dateOnly(start);
    final e = _dateOnly(end);
    if (e.isBefore(s)) return false;
    return e.difference(s).inDays + 1 <= maxCustomRangeDays;
  }

  String? customRangeError(DateTime start, DateTime end) {
    final s = _dateOnly(start);
    final e = _dateOnly(end);
    if (e.isBefore(s)) return 'End date must be on or after start date';
    if (e.difference(s).inDays + 1 > maxCustomRangeDays) {
      return 'Range cannot exceed $maxCustomRangeDays days';
    }
    return null;
  }

  ExpenseDateFilter copyWith({
    ExpenseDatePreset? preset,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    return ExpenseDateFilter(
      preset: preset ?? this.preset,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
    );
  }
}
