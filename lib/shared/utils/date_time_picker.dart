import 'package:flutter/material.dart';

/// Shows date then time pickers and returns the combined local [DateTime].
Future<DateTime?> pickDateTime(
  BuildContext context, {
  DateTime? initial,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  final now = DateTime.now();
  final seed = initial ?? now;

  final date = await showDatePicker(
    context: context,
    initialDate: seed,
    firstDate: firstDate ?? now.subtract(const Duration(days: 1)),
    lastDate: lastDate ?? now.add(const Duration(days: 365 * 3)),
  );
  if (date == null || !context.mounted) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(seed),
  );
  if (time == null) return null;

  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

/// Shows a time picker and returns the selected [TimeOfDay].
Future<TimeOfDay?> pickTime(
  BuildContext context, {
  TimeOfDay? initial,
}) {
  return showTimePicker(
    context: context,
    initialTime: initial ?? TimeOfDay.now(),
  );
}
