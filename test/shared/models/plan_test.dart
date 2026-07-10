import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/models/plan.dart';

void main() {
  group('Plan getters', () {
    test('isOpen when status is open', () {
      const plan = Plan(
        id: 'p1',
        householdId: 'hh',
        createdBy: 'u1',
        scope: 'household',
        planType: 'task',
        title: 'Buy milk',
        status: 'open',
        reminderEnabled: false,
      );
      expect(plan.isOpen, isTrue);
      expect(plan.isPersonal, isFalse);
    });

    test('isPersonal for personal scope', () {
      const plan = Plan(
        id: 'p1',
        householdId: 'hh',
        createdBy: 'u1',
        scope: 'personal',
        planType: 'task',
        title: 'Private',
        status: 'done',
        reminderEnabled: false,
      );
      expect(plan.isPersonal, isTrue);
      expect(plan.isOpen, isFalse);
    });
  });

  group('Plan.fromJson', () {
    test('parses nested member names', () {
      final plan = Plan.fromJson({
        'id': 'p1',
        'household_id': 'hh',
        'created_by': 'u1',
        'scope': 'household',
        'plan_type': 'meal',
        'title': 'Dinner',
        'status': 'open',
        'meal_slot': 'dinner',
        'about_member': {'display_name': 'Alex'},
        'assigned_member': {'display_name': 'Sam'},
      });
      expect(plan.mealSlot, 'dinner');
      expect(plan.aboutMemberName, 'Alex');
      expect(plan.assignedToName, 'Sam');
      expect(plan.reminderEnabled, isFalse);
    });
  });

  group('Plan serialization', () {
    test('toInsertJson includes reminder fields when enabled', () {
      final plan = Plan(
        id: 'p1',
        householdId: 'hh',
        createdBy: 'u1',
        scope: 'household',
        planType: 'task',
        title: 'Task',
        status: 'open',
        reminderEnabled: true,
        reminderAt: DateTime.utc(2026, 7, 8, 10),
      );
      final json = plan.toInsertJson('hh', 'u1');
      expect(json['reminder_enabled'], isTrue);
      expect(json['reminder_at'], isNotNull);
      expect(json['reminder_notify_user_id'], 'u1');
    });
  });
}
