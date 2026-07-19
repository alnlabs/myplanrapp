import '../constants/reminder_repeat.dart';

/// Weekday integers follow Dart's [DateTime.weekday]: Mon = 1 … Sun = 7.
class ReminderWeekdays {
  ReminderWeekdays._();

  static const monday = DateTime.monday; // 1
  static const friday = DateTime.friday; // 5
  static const saturday = DateTime.saturday; // 6
  static const sunday = DateTime.sunday; // 7

  static const weekdays = [1, 2, 3, 4, 5];
  static const weekend = [6, 7];

  static const shortLabels = <int, String>{
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
    7: 'Sun',
  };

  static const longLabels = <int, String>{
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    7: 'Sunday',
  };

  static String shortLabel(int weekday) => shortLabels[weekday] ?? '?';
  static String longLabel(int weekday) => longLabels[weekday] ?? '?';
}

/// How a monthly reminder repeats.
enum MonthlyMode {
  /// Same calendar day each month (e.g. the 15th).
  dayOfMonth,

  /// Same weekday position each month (e.g. the 3rd Tuesday). The position and
  /// weekday are derived from the reminder anchor date.
  nthWeekday,
}

/// A full description of how a reminder repeats. This supersedes the plain
/// [ReminderRepeat] string: [frequency] still uses the same values, but the
/// spec adds [interval] (every N), specific [daysOfWeek] for weekly patterns,
/// and a [monthlyMode] for monthly patterns.
class ReminderRepeatSpec {
  const ReminderRepeatSpec({
    this.frequency = ReminderRepeat.none,
    this.interval = 1,
    this.daysOfWeek = const <int>[],
    this.monthlyMode = MonthlyMode.dayOfMonth,
  });

  /// One of [ReminderRepeat] values.
  final String frequency;

  /// Repeat every N units of [frequency]. Always >= 1.
  final int interval;

  /// For weekly patterns: the weekdays it fires on (1 = Mon … 7 = Sun). Empty
  /// means "the same weekday as the anchor".
  final List<int> daysOfWeek;

  /// For monthly patterns only.
  final MonthlyMode monthlyMode;

  static const none = ReminderRepeatSpec();

  bool get isRecurring => ReminderRepeat.isRecurring(frequency);
  bool get isWeekly => frequency == ReminderRepeat.weekly;
  bool get isMonthly => frequency == ReminderRepeat.monthly;

  /// Sorted, de-duplicated weekdays (1–7 only).
  List<int> get sortedDays {
    final set = daysOfWeek.where((d) => d >= 1 && d <= 7).toSet().toList()
      ..sort();
    return set;
  }

  ReminderRepeatSpec copyWith({
    String? frequency,
    int? interval,
    List<int>? daysOfWeek,
    MonthlyMode? monthlyMode,
  }) {
    return ReminderRepeatSpec(
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      monthlyMode: monthlyMode ?? this.monthlyMode,
    );
  }

  // ---- Presets --------------------------------------------------------------

  static const weekdays = ReminderRepeatSpec(
    frequency: ReminderRepeat.weekly,
    daysOfWeek: ReminderWeekdays.weekdays,
  );

  static const weekends = ReminderRepeatSpec(
    frequency: ReminderRepeat.weekly,
    daysOfWeek: ReminderWeekdays.weekend,
  );

  // ---- Serialization --------------------------------------------------------

  /// Builds a spec from a legacy plain-frequency string (interval 1, no days).
  factory ReminderRepeatSpec.fromLegacy(String? repeat) =>
      ReminderRepeatSpec(frequency: ReminderRepeat.normalize(repeat));

  /// Builds a spec from the stored `repeat_config` JSON, falling back to the
  /// legacy `repeat` column when the config is absent (older rows).
  factory ReminderRepeatSpec.fromConfig(
    Map<String, dynamic>? config, {
    String? legacyRepeat,
  }) {
    if (config == null || config.isEmpty) {
      return ReminderRepeatSpec.fromLegacy(legacyRepeat);
    }
    final frequency = ReminderRepeat.normalize(config['frequency'] as String?);
    final rawInterval = config['interval'];
    final interval = rawInterval is num ? rawInterval.toInt() : 1;
    final rawDays = config['days_of_week'];
    final days = rawDays is List
        ? rawDays.map((e) => (e as num).toInt()).toList()
        : const <int>[];
    final mode = config['monthly_mode'] == 'nth_weekday'
        ? MonthlyMode.nthWeekday
        : MonthlyMode.dayOfMonth;
    return ReminderRepeatSpec(
      frequency: frequency,
      interval: interval < 1 ? 1 : interval,
      daysOfWeek: days,
      monthlyMode: mode,
    );
  }

  /// The JSON persisted in `repeat_config`. Returns null for one-time reminders
  /// and for the plain interval-1 frequencies that need no extra config.
  Map<String, dynamic>? toConfigJson() {
    if (!isRecurring) return null;
    final needsConfig = interval != 1 ||
        (isWeekly && sortedDays.isNotEmpty) ||
        (isMonthly && monthlyMode == MonthlyMode.nthWeekday);
    if (!needsConfig) return null;
    return {
      'frequency': frequency,
      'interval': interval,
      if (isWeekly && sortedDays.isNotEmpty) 'days_of_week': sortedDays,
      if (isMonthly)
        'monthly_mode':
            monthlyMode == MonthlyMode.nthWeekday ? 'nth_weekday' : 'day_of_month',
    };
  }

  /// The coarse frequency string stored in the legacy `repeat` column so older
  /// clients and simple queries keep working.
  String get legacyFrequency => frequency;

  @override
  bool operator ==(Object other) =>
      other is ReminderRepeatSpec &&
      other.frequency == frequency &&
      other.interval == interval &&
      other.monthlyMode == monthlyMode &&
      _listEquals(other.sortedDays, sortedDays);

  @override
  int get hashCode => Object.hash(
        frequency,
        interval,
        monthlyMode,
        Object.hashAll(sortedDays),
      );
}

bool _listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
