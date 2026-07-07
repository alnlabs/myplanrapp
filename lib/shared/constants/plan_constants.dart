class PlanTypes {
  PlanTypes._();

  static const purchase = 'purchase';
  static const task = 'task';
  static const meal = 'meal';
  static const medicine = 'medicine';
  static const other = 'other';

  static const all = [
    (value: purchase, label: 'Purchase'),
    (value: task, label: 'Task'),
    (value: meal, label: 'Meal'),
    (value: medicine, label: 'Medicine'),
    (value: other, label: 'Other'),
  ];

  static String labelFor(String value) {
    return all
        .firstWhere((t) => t.value == value, orElse: () => all.last)
        .label;
  }
}

class PlanScopes {
  PlanScopes._();

  static const personal = 'personal';
  static const household = 'household';

  static const all = [
    (value: personal, label: 'Personal'),
    (value: household, label: 'Family'),
  ];
}
