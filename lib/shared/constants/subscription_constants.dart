class BillingCycles {
  BillingCycles._();

  static const monthly = 'monthly';
  static const yearly = 'yearly';

  static const all = [
    (value: monthly, label: 'Monthly'),
    (value: yearly, label: 'Yearly'),
  ];

  static String labelFor(String value) {
    for (final c in all) {
      if (c.value == value) return c.label;
    }
    return value;
  }
}

class ReminderDaysBefore {
  ReminderDaysBefore._();

  static const options = [1, 3, 7];
}
