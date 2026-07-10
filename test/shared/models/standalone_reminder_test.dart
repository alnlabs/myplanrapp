import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/models/standalone_reminder.dart';

void main() {
  group('StandaloneReminder', () {
    final reminderAt = DateTime.utc(2026, 7, 8, 10, 30);

    test('fromJson parses fields', () {
      final reminder = StandaloneReminder.fromJson({
        'id': 'r1',
        'household_id': 'hh',
        'user_id': 'u1',
        'title': 'Call plumber',
        'notes': 'Kitchen sink',
        'reminder_at': '2026-07-08T10:30:00Z',
        'is_active': true,
      });
      expect(reminder.title, 'Call plumber');
      expect(reminder.notes, 'Kitchen sink');
      expect(reminder.isActive, isTrue);
    });

    test('toInsertJson converts reminder to UTC', () {
      final reminder = StandaloneReminder(
        id: 'r1',
        householdId: 'hh',
        userId: 'u1',
        title: 'Task',
        reminderAt: reminderAt,
        isActive: true,
      );
      final json = reminder.toInsertJson('hh', 'u1');
      expect(json['household_id'], 'hh');
      expect(json['reminder_at'], reminderAt.toUtc().toIso8601String());
    });

    test('copyWith updates selected fields', () {
      final original = StandaloneReminder(
        id: 'r1',
        householdId: 'hh',
        userId: 'u1',
        title: 'Old',
        reminderAt: reminderAt,
        isActive: true,
      );
      final updated = original.copyWith(title: 'New', isActive: false);
      expect(updated.title, 'New');
      expect(updated.isActive, isFalse);
      expect(updated.reminderAt, reminderAt);
    });
  });
}
