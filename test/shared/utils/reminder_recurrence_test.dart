import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/constants/reminder_repeat.dart';
import 'package:myplanr/shared/models/reminder_repeat_spec.dart';
import 'package:myplanr/shared/utils/reminder_recurrence.dart';

void main() {
  // 2026-01-05 is a Monday.
  final anchor = DateTime(2026, 1, 5, 9, 0);

  group('occurrences', () {
    test('daily interval 1 steps by one day', () {
      const spec = ReminderRepeatSpec(frequency: ReminderRepeat.daily);
      final occ = ReminderRecurrence.occurrences(spec, anchor, anchor, 3);
      expect(occ, [
        DateTime(2026, 1, 5, 9, 0),
        DateTime(2026, 1, 6, 9, 0),
        DateTime(2026, 1, 7, 9, 0),
      ]);
    });

    test('daily interval 3 steps by three days', () {
      const spec =
          ReminderRepeatSpec(frequency: ReminderRepeat.daily, interval: 3);
      final occ = ReminderRecurrence.occurrences(spec, anchor, anchor, 3);
      expect(occ, [
        DateTime(2026, 1, 5, 9, 0),
        DateTime(2026, 1, 8, 9, 0),
        DateTime(2026, 1, 11, 9, 0),
      ]);
    });

    test('weekly weekdays preset only fires Mon-Fri, in order', () {
      final spec = ReminderRepeatSpec.weekdays;
      final occ = ReminderRecurrence.occurrences(spec, anchor, anchor, 5);
      expect(occ.map((d) => d.weekday).toList(), [1, 2, 3, 4, 5]);
      // First is the anchor Monday.
      expect(occ.first, DateTime(2026, 1, 5, 9, 0));
    });

    test('weekly weekends preset only fires Sat/Sun', () {
      final spec = ReminderRepeatSpec.weekends;
      final occ = ReminderRecurrence.occurrences(spec, anchor, anchor, 4);
      expect(occ.every((d) => d.weekday == 6 || d.weekday == 7), isTrue);
    });

    test('every 2 weeks keeps a 14-day gap per weekday', () {
      const spec = ReminderRepeatSpec(
        frequency: ReminderRepeat.weekly,
        interval: 2,
        daysOfWeek: [1],
      );
      final occ = ReminderRecurrence.occurrences(spec, anchor, anchor, 3);
      expect(occ, [
        DateTime(2026, 1, 5, 9, 0),
        DateTime(2026, 1, 19, 9, 0),
        DateTime(2026, 2, 2, 9, 0),
      ]);
    });

    test('monthly day-of-month keeps the same day', () {
      const spec = ReminderRepeatSpec(frequency: ReminderRepeat.monthly);
      final occ = ReminderRecurrence.occurrences(spec, anchor, anchor, 3);
      expect(occ, [
        DateTime(2026, 1, 5, 9, 0),
        DateTime(2026, 2, 5, 9, 0),
        DateTime(2026, 3, 5, 9, 0),
      ]);
    });

    test('monthly by weekday keeps the nth weekday (1st Monday)', () {
      const spec = ReminderRepeatSpec(
        frequency: ReminderRepeat.monthly,
        monthlyMode: MonthlyMode.nthWeekday,
      );
      final occ = ReminderRecurrence.occurrences(spec, anchor, anchor, 3);
      // Every occurrence is the first Monday of its month.
      for (final d in occ) {
        expect(d.weekday, DateTime.monday);
        expect(d.day, lessThanOrEqualTo(7));
      }
      expect(occ.first, DateTime(2026, 1, 5, 9, 0));
    });

    test('yearly keeps month and day', () {
      const spec = ReminderRepeatSpec(frequency: ReminderRepeat.yearly);
      final occ = ReminderRecurrence.occurrences(spec, anchor, anchor, 2);
      expect(occ, [
        DateTime(2026, 1, 5, 9, 0),
        DateTime(2027, 1, 5, 9, 0),
      ]);
    });

    test('skips occurrences before the from bound', () {
      const spec = ReminderRepeatSpec(frequency: ReminderRepeat.daily);
      final from = DateTime(2026, 1, 8, 12, 0);
      final occ = ReminderRecurrence.occurrences(spec, anchor, from, 2);
      expect(occ, [
        DateTime(2026, 1, 9, 9, 0),
        DateTime(2026, 1, 10, 9, 0),
      ]);
    });
  });

  group('scheduleEntries', () {
    final before = anchor.subtract(const Duration(days: 1));

    test('one-time future reminder yields a single one-shot', () {
      final entries =
          ReminderRecurrence.scheduleEntries(ReminderRepeatSpec.none, anchor, before);
      expect(entries.length, 1);
      expect(entries.first.component, isNull);
      expect(entries.first.when, anchor);
    });

    test('one-time past reminder yields nothing', () {
      final entries = ReminderRecurrence.scheduleEntries(
          ReminderRepeatSpec.none, anchor, anchor.add(const Duration(days: 1)));
      expect(entries, isEmpty);
    });

    test('daily uses a single native time entry', () {
      const spec = ReminderRepeatSpec(frequency: ReminderRepeat.daily);
      final entries = ReminderRecurrence.scheduleEntries(spec, anchor, before);
      expect(entries.length, 1);
      expect(entries.first.component, ReminderRepeatComponent.time);
    });

    test('weekdays preset yields five native weekday entries', () {
      final entries =
          ReminderRecurrence.scheduleEntries(ReminderRepeatSpec.weekdays, anchor, before);
      expect(entries.length, 5);
      expect(
        entries.every(
            (e) => e.component == ReminderRepeatComponent.dayOfWeekAndTime),
        isTrue,
      );
    });

    test('every-N pattern pre-schedules one-shots', () {
      const spec =
          ReminderRepeatSpec(frequency: ReminderRepeat.daily, interval: 2);
      final entries = ReminderRecurrence.scheduleEntries(spec, anchor, before);
      expect(entries.length, ReminderRecurrence.preScheduleCount);
      expect(entries.every((e) => e.component == null), isTrue);
    });

    test('monthly by weekday pre-schedules one-shots', () {
      const spec = ReminderRepeatSpec(
        frequency: ReminderRepeat.monthly,
        monthlyMode: MonthlyMode.nthWeekday,
      );
      final entries = ReminderRecurrence.scheduleEntries(spec, anchor, before);
      expect(entries.every((e) => e.component == null), isTrue);
      expect(entries.isNotEmpty, isTrue);
    });
  });

  group('describe', () {
    test('presets and intervals', () {
      expect(ReminderRecurrence.describe(ReminderRepeatSpec.none, anchor),
          'One-time');
      expect(
          ReminderRecurrence.describe(
              const ReminderRepeatSpec(frequency: ReminderRepeat.daily), anchor),
          'Daily');
      expect(
          ReminderRecurrence.describe(
              const ReminderRepeatSpec(
                  frequency: ReminderRepeat.daily, interval: 2),
              anchor),
          'Every 2 days');
      expect(ReminderRecurrence.describe(ReminderRepeatSpec.weekdays, anchor),
          'Every weekday');
      expect(ReminderRecurrence.describe(ReminderRepeatSpec.weekends, anchor),
          'Weekends');
      expect(
          ReminderRecurrence.describe(
              const ReminderRepeatSpec(
                frequency: ReminderRepeat.monthly,
                monthlyMode: MonthlyMode.nthWeekday,
              ),
              anchor),
          'Monthly on the 1st Monday');
    });
  });

  group('serialization', () {
    test('config round-trips for a custom weekly pattern', () {
      const spec = ReminderRepeatSpec(
        frequency: ReminderRepeat.weekly,
        interval: 2,
        daysOfWeek: [2, 4],
      );
      final json = spec.toConfigJson();
      expect(json, {
        'frequency': 'weekly',
        'interval': 2,
        'days_of_week': [2, 4],
      });
      final parsed = ReminderRepeatSpec.fromConfig(json);
      expect(parsed, spec);
    });

    test('plain interval-1 frequency needs no config json', () {
      const spec = ReminderRepeatSpec(frequency: ReminderRepeat.daily);
      expect(spec.toConfigJson(), isNull);
    });

    test('legacy repeat string maps to a spec', () {
      final spec = ReminderRepeatSpec.fromConfig(null, legacyRepeat: 'weekly');
      expect(spec.frequency, ReminderRepeat.weekly);
      expect(spec.interval, 1);
    });
  });
}
