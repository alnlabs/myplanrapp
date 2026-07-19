import '../constants/reminder_repeat.dart';
import '../models/reminder_repeat_spec.dart';

/// The native OS recurrence unit a schedule entry maps to. `null` (see
/// [ReminderScheduleEntry.component]) means the entry is a one-shot that must be
/// re-scheduled by the app (used for patterns the OS can't express natively).
enum ReminderRepeatComponent { time, dayOfWeekAndTime, dayOfMonthAndTime, dateAndTime }

/// One notification to schedule for a reminder. A single reminder can produce
/// several entries (e.g. one per selected weekday, or a batch of pre-computed
/// one-shots for non-native patterns).
class ReminderScheduleEntry {
  const ReminderScheduleEntry(this.when, this.component);

  final DateTime when;
  final ReminderRepeatComponent? component;
}

/// Turns a [ReminderRepeatSpec] + anchor time into concrete occurrences and
/// notification schedule entries. All date math is done in local time.
class ReminderRecurrence {
  ReminderRecurrence._();

  /// How many one-shots we pre-schedule for patterns the OS can't repeat
  /// natively (every-N and monthly-by-weekday). The app tops these up whenever
  /// reminders are re-synced.
  static const preScheduleCount = 16;

  /// Whether [spec] can be expressed with a single native repeating
  /// notification per firing day.
  static bool isNativelyRepeatable(ReminderRepeatSpec spec) {
    if (!spec.isRecurring || spec.interval != 1) return false;
    switch (spec.frequency) {
      case ReminderRepeat.daily:
      case ReminderRepeat.weekly:
      case ReminderRepeat.yearly:
        return true;
      case ReminderRepeat.monthly:
        return spec.monthlyMode == MonthlyMode.dayOfMonth;
      default:
        return false;
    }
  }

  /// Weekdays a weekly spec fires on; falls back to the anchor's weekday.
  static List<int> weeklyDays(ReminderRepeatSpec spec, DateTime anchor) {
    final days = spec.sortedDays;
    return days.isNotEmpty ? days : [anchor.weekday];
  }

  /// The next occurrence at or after [from], or null if none (e.g. a one-time
  /// reminder already in the past).
  static DateTime? nextOccurrence(
    ReminderRepeatSpec spec,
    DateTime anchor,
    DateTime from,
  ) {
    if (!spec.isRecurring) {
      return anchor.isBefore(from) ? null : anchor;
    }
    final list = occurrences(spec, anchor, from, 1);
    return list.isEmpty ? null : list.first;
  }

  /// Builds the notification entries for [spec]. For natively-repeatable specs
  /// this is one entry per firing day tagged with a repeat component. Otherwise
  /// it is up to [preScheduleCount] one-shot entries.
  static List<ReminderScheduleEntry> scheduleEntries(
    ReminderRepeatSpec spec,
    DateTime anchor,
    DateTime now,
  ) {
    if (!spec.isRecurring) {
      return anchor.isBefore(now)
          ? const []
          : [ReminderScheduleEntry(anchor, null)];
    }

    if (isNativelyRepeatable(spec)) {
      switch (spec.frequency) {
        case ReminderRepeat.daily:
          final first = occurrences(spec, anchor, now, 1);
          return first.isEmpty
              ? const []
              : [ReminderScheduleEntry(first.first, ReminderRepeatComponent.time)];
        case ReminderRepeat.weekly:
          final entries = <ReminderScheduleEntry>[];
          for (final day in weeklyDays(spec, anchor)) {
            final sub = spec.copyWith(daysOfWeek: [day]);
            final first = occurrences(sub, anchor, now, 1);
            if (first.isNotEmpty) {
              entries.add(ReminderScheduleEntry(
                  first.first, ReminderRepeatComponent.dayOfWeekAndTime));
            }
          }
          return entries;
        case ReminderRepeat.monthly:
          final first = occurrences(spec, anchor, now, 1);
          return first.isEmpty
              ? const []
              : [
                  ReminderScheduleEntry(
                      first.first, ReminderRepeatComponent.dayOfMonthAndTime)
                ];
        case ReminderRepeat.yearly:
          final first = occurrences(spec, anchor, now, 1);
          return first.isEmpty
              ? const []
              : [
                  ReminderScheduleEntry(
                      first.first, ReminderRepeatComponent.dateAndTime)
                ];
      }
    }

    return occurrences(spec, anchor, now, preScheduleCount)
        .map((d) => ReminderScheduleEntry(d, null))
        .toList();
  }

  /// Generates up to [count] occurrences at or after [from] (and never before
  /// the anchor), in ascending order.
  static List<DateTime> occurrences(
    ReminderRepeatSpec spec,
    DateTime anchor,
    DateTime from,
    int count,
  ) {
    if (count <= 0 || !spec.isRecurring) {
      if (!spec.isRecurring) {
        final a = _atAnchorTime(anchor.year, anchor.month, anchor.day, anchor);
        return (!a.isBefore(from) && !a.isBefore(_floor(anchor))) ? [a] : const [];
      }
      return const [];
    }

    final interval = spec.interval < 1 ? 1 : spec.interval;
    final lowerBound = from.isAfter(_floor(anchor)) ? from : _floor(anchor);

    switch (spec.frequency) {
      case ReminderRepeat.daily:
        return _daily(anchor, interval, lowerBound, count);
      case ReminderRepeat.weekly:
        return _weekly(spec, anchor, interval, lowerBound, count);
      case ReminderRepeat.monthly:
        return _monthly(spec, anchor, interval, lowerBound, count);
      case ReminderRepeat.yearly:
        return _yearly(anchor, interval, lowerBound, count);
      default:
        return const [];
    }
  }

  // ---- Per-frequency generators --------------------------------------------

  static List<DateTime> _daily(
    DateTime anchor,
    int interval,
    DateTime lowerBound,
    int count,
  ) {
    var current = _atAnchorTime(anchor.year, anchor.month, anchor.day, anchor);
    // Jump close to the lower bound to avoid long loops for old anchors.
    if (current.isBefore(lowerBound)) {
      final days = lowerBound.difference(current).inDays;
      final jumps = days ~/ interval;
      current = current.add(Duration(days: jumps * interval));
      while (current.isBefore(lowerBound)) {
        current = current.add(Duration(days: interval));
      }
    }
    final result = <DateTime>[];
    while (result.length < count) {
      result.add(current);
      current = current.add(Duration(days: interval));
    }
    return result;
  }

  static List<DateTime> _weekly(
    ReminderRepeatSpec spec,
    DateTime anchor,
    int interval,
    DateTime lowerBound,
    int count,
  ) {
    final days = weeklyDays(spec, anchor);
    // Monday of the anchor's week.
    final anchorDate = DateTime(anchor.year, anchor.month, anchor.day);
    var weekStart = anchorDate.subtract(Duration(days: anchor.weekday - 1));
    final stepDays = 7 * interval;

    // Advance whole steps to near the lower bound.
    if (weekStart.isBefore(lowerBound)) {
      final diff = lowerBound.difference(weekStart).inDays;
      final jumps = diff ~/ stepDays;
      weekStart = weekStart.add(Duration(days: jumps * stepDays));
    }

    final result = <DateTime>[];
    var guard = 0;
    while (result.length < count && guard < 1000) {
      for (final day in days) {
        final date = weekStart.add(Duration(days: day - 1));
        final occ = _atAnchorTime(date.year, date.month, date.day, anchor);
        if (!occ.isBefore(lowerBound)) {
          result.add(occ);
          if (result.length >= count) break;
        }
      }
      weekStart = weekStart.add(Duration(days: stepDays));
      guard++;
    }
    result.sort();
    return result.take(count).toList();
  }

  static List<DateTime> _monthly(
    ReminderRepeatSpec spec,
    DateTime anchor,
    int interval,
    DateTime lowerBound,
    int count,
  ) {
    final byWeekday = spec.monthlyMode == MonthlyMode.nthWeekday;
    final weekday = anchor.weekday;
    final nth = ((anchor.day - 1) ~/ 7) + 1; // 1..5

    final result = <DateTime>[];
    var year = anchor.year;
    var monthIndex = anchor.month - 1; // 0-based
    var guard = 0;
    while (result.length < count && guard < 1200) {
      final y = year + (monthIndex ~/ 12);
      final m = (monthIndex % 12) + 1;
      DateTime? occ;
      if (byWeekday) {
        final date = _nthWeekdayOfMonth(y, m, weekday, nth);
        if (date != null) {
          occ = _atAnchorTime(date.year, date.month, date.day, anchor);
        }
      } else {
        final day = anchor.day <= _daysInMonth(y, m)
            ? anchor.day
            : _daysInMonth(y, m);
        occ = _atAnchorTime(y, m, day, anchor);
      }
      if (occ != null && !occ.isBefore(lowerBound)) {
        result.add(occ);
      }
      monthIndex += interval;
      guard++;
    }
    return result.take(count).toList();
  }

  static List<DateTime> _yearly(
    DateTime anchor,
    int interval,
    DateTime lowerBound,
    int count,
  ) {
    final result = <DateTime>[];
    var year = anchor.year;
    var guard = 0;
    while (result.length < count && guard < 500) {
      final day = anchor.day <= _daysInMonth(year, anchor.month)
          ? anchor.day
          : _daysInMonth(year, anchor.month);
      final occ = _atAnchorTime(year, anchor.month, day, anchor);
      if (!occ.isBefore(lowerBound)) {
        result.add(occ);
      }
      year += interval;
      guard++;
    }
    return result.take(count).toList();
  }

  // ---- Date helpers ---------------------------------------------------------

  static DateTime _atAnchorTime(int year, int month, int day, DateTime anchor) =>
      DateTime(year, month, day, anchor.hour, anchor.minute);

  static DateTime _floor(DateTime d) => DateTime(d.year, d.month, d.day, d.hour, d.minute);

  static int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  /// The [nth] (1..5) occurrence of [weekday] in the given month. When [nth] is
  /// 5 or the month has no 5th occurrence, returns the last one.
  static DateTime? _nthWeekdayOfMonth(int year, int month, int weekday, int nth) {
    final first = DateTime(year, month, 1);
    var offset = (weekday - first.weekday) % 7;
    if (offset < 0) offset += 7;
    final firstDay = 1 + offset;
    final daysInMonth = _daysInMonth(year, month);

    if (nth >= 5) {
      // Last occurrence of the weekday.
      var day = firstDay;
      while (day + 7 <= daysInMonth) {
        day += 7;
      }
      return DateTime(year, month, day);
    }
    final day = firstDay + (nth - 1) * 7;
    if (day > daysInMonth) {
      // Requested nth doesn't exist (e.g. 4th when only 3) — fall back to last.
      var last = firstDay;
      while (last + 7 <= daysInMonth) {
        last += 7;
      }
      return DateTime(year, month, last);
    }
    return DateTime(year, month, day);
  }

  // ---- Human-readable labels ------------------------------------------------

  /// A full description of the pattern, e.g. "Every 2 weeks on Mon, Thu" or
  /// "Monthly on the 3rd Tuesday".
  static String describe(ReminderRepeatSpec spec, DateTime anchor) {
    if (!spec.isRecurring) return 'One-time';
    final n = spec.interval < 1 ? 1 : spec.interval;

    switch (spec.frequency) {
      case ReminderRepeat.daily:
        return n == 1 ? 'Daily' : 'Every $n days';
      case ReminderRepeat.weekly:
        final days = weeklyDays(spec, anchor);
        if (n == 1 && _sameDays(days, ReminderWeekdays.weekdays)) {
          return 'Every weekday';
        }
        if (n == 1 && _sameDays(days, ReminderWeekdays.weekend)) {
          return 'Weekends';
        }
        final base = n == 1 ? 'Weekly' : 'Every $n weeks';
        final labels = days.map(ReminderWeekdays.shortLabel).join(', ');
        return '$base on $labels';
      case ReminderRepeat.monthly:
        if (spec.monthlyMode == MonthlyMode.nthWeekday) {
          final nth = ((anchor.day - 1) ~/ 7) + 1;
          final base = n == 1 ? 'Monthly' : 'Every $n months';
          return '$base on the ${_ordinal(nth)} ${ReminderWeekdays.longLabel(anchor.weekday)}';
        }
        final base = n == 1 ? 'Monthly' : 'Every $n months';
        return '$base on day ${anchor.day}';
      case ReminderRepeat.yearly:
        return n == 1 ? 'Yearly' : 'Every $n years';
      default:
        return 'One-time';
    }
  }

  static String _ordinal(int n) => switch (n) {
        1 => '1st',
        2 => '2nd',
        3 => '3rd',
        4 => '4th',
        _ => 'last',
      };

  static bool _sameDays(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    final sa = [...a]..sort();
    final sb = [...b]..sort();
    for (var i = 0; i < sa.length; i++) {
      if (sa[i] != sb[i]) return false;
    }
    return true;
  }
}
