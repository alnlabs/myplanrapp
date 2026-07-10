class MealSlots {
  MealSlots._();

  static const breakfast = 'breakfast';
  static const lunch = 'lunch';
  static const dinner = 'dinner';
  static const snack = 'snack';

  static const primary = [breakfast, lunch, dinner];

  static const all = [
    (value: breakfast, label: 'Breakfast'),
    (value: lunch, label: 'Lunch'),
    (value: dinner, label: 'Dinner'),
    (value: snack, label: 'Snack'),
  ];

  static String labelFor(String value) {
    return all
        .firstWhere((s) => s.value == value, orElse: () => all.first)
        .label;
  }

  static bool isValid(String? value) {
    if (value == null) return false;
    return all.any((s) => s.value == value);
  }

  static DateTime defaultDueAtForSlot(String slot) {
    final now = DateTime.now();
    final hour = switch (slot) {
      breakfast => 8,
      lunch => 13,
      dinner => 19,
      snack => 16,
      _ => 12,
    };
    return DateTime(now.year, now.month, now.day, hour);
  }
}
