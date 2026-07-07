class PlanTypes {
  PlanTypes._();

  static const purchase = 'purchase';
  static const task = 'task';
  static const meal = 'meal';
  static const medicine = 'medicine';
  static const bill = 'bill';
  static const appointment = 'appointment';
  static const event = 'event';
  static const travel = 'travel';
  static const chore = 'chore';
  static const maintenance = 'maintenance';
  static const birthday = 'birthday';
  static const school = 'school';
  static const pet = 'pet';
  static const childcare = 'childcare';
  static const outing = 'outing';
  static const other = 'other';

  static const all = [
    (value: task, label: 'Task'),
    (value: purchase, label: 'Purchase'),
    (value: appointment, label: 'Appointment'),
    (value: medicine, label: 'Medicine'),
    (value: travel, label: 'Travel'),
    (value: meal, label: 'Meal'),
    (value: bill, label: 'Bill'),
    (value: event, label: 'Event'),
    (value: chore, label: 'Chore'),
    (value: maintenance, label: 'Maintenance'),
    (value: birthday, label: 'Birthday'),
    (value: school, label: 'School'),
    (value: pet, label: 'Pet care'),
    (value: childcare, label: 'Childcare'),
    (value: outing, label: 'Family outing'),
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
