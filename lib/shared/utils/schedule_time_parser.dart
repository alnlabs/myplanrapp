import 'package:flutter/material.dart';

TimeOfDay? parseScheduleTime(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final match24 = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(trimmed);
  if (match24 != null) {
    final hour = int.tryParse(match24.group(1)!);
    final minute = int.tryParse(match24.group(2)!);
    if (hour != null &&
        minute != null &&
        hour >= 0 &&
        hour < 24 &&
        minute >= 0 &&
        minute < 60) {
      return TimeOfDay(hour: hour, minute: minute);
    }
  }

  final upper = trimmed.toUpperCase();
  final match12 = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$').firstMatch(upper);
  if (match12 != null) {
    var hour = int.tryParse(match12.group(1)!);
    final minute = int.tryParse(match12.group(2)!);
    final period = match12.group(3);
    if (hour == null || minute == null || minute >= 60) return null;
    if (period == 'PM' && hour < 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    if (hour >= 0 && hour < 24) {
      return TimeOfDay(hour: hour, minute: minute);
    }
  }

  return null;
}

String formatScheduleTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
