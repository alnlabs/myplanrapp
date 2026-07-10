/// Computes the first due date for a monthly recurring money rule.
DateTime nextMonthlyRecurringDueDate({
  required DateTime reference,
  required int dayOfMonth,
}) {
  final today = DateTime(reference.year, reference.month, reference.day);
  final nextDue = DateTime(reference.year, reference.month, dayOfMonth);
  if (nextDue.isBefore(today)) {
    return DateTime(reference.year, reference.month + 1, dayOfMonth);
  }
  return nextDue;
}

/// Returns [dayOfMonth] only when frequency is monthly.
int? recurringDayOfMonthForFrequency(String frequency, int dayOfMonth) {
  return frequency == 'monthly' ? dayOfMonth : null;
}
