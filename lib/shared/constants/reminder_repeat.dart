/// Repeat frequencies for standalone reminders. Stored as a text column on the
/// `reminders` table and mapped to OS repeating notifications.
class ReminderRepeat {
  ReminderRepeat._();

  static const none = 'none';
  static const daily = 'daily';
  static const weekly = 'weekly';
  static const monthly = 'monthly';
  static const yearly = 'yearly';

  static const all = [
    (value: none, label: 'Does not repeat'),
    (value: daily, label: 'Daily'),
    (value: weekly, label: 'Weekly'),
    (value: monthly, label: 'Monthly'),
    (value: yearly, label: 'Yearly'),
  ];

  /// Falls back to [none] for null/unknown values.
  static String normalize(String? value) {
    if (value == null) return none;
    return all.any((o) => o.value == value) ? value : none;
  }

  static bool isRecurring(String? value) => normalize(value) != none;

  static String labelFor(String value) {
    for (final option in all) {
      if (option.value == value) return option.label;
    }
    return value;
  }

  /// Short label for reminder rows, e.g. "Repeats weekly".
  static String repeatsLabel(String value) => switch (value) {
        daily => 'Repeats daily',
        weekly => 'Repeats weekly',
        monthly => 'Repeats monthly',
        yearly => 'Repeats yearly',
        _ => 'One-time',
      };
}
