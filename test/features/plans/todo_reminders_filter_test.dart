import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/features/plans/data/plans_filter.dart';
import 'package:myplanr/features/plans/data/todo_reminders_filter.dart';
import 'package:myplanr/shared/models/app_reminder_item.dart';

AppReminderItem _reminder(ReminderSourceType type, {String id = 'r1'}) {
  return AppReminderItem(
    id: id,
    sourceType: type,
    sourceId: 'src-$id',
    title: 'Reminder $id',
  );
}

void main() {
  group('TodoRemindersFilter.fromQuery', () {
    test('parses known filter names', () {
      expect(
        TodoRemindersFilter.fromQuery('medicine'),
        TodoRemindersFilter.medicine,
      );
    });

    test('returns null for unknown or empty', () {
      expect(TodoRemindersFilter.fromQuery(null), isNull);
      expect(TodoRemindersFilter.fromQuery(''), isNull);
      expect(TodoRemindersFilter.fromQuery('unknown'), isNull);
    });
  });

  group('showsPlans / showsReminders', () {
    test('all shows both', () {
      expect(TodoRemindersFilter.all.showsPlans, isTrue);
      expect(TodoRemindersFilter.all.showsReminders, isTrue);
    });

    test('meals shows plans only', () {
      expect(TodoRemindersFilter.meals.showsPlans, isTrue);
      expect(TodoRemindersFilter.meals.showsReminders, isFalse);
    });

    test('medicine shows reminders only', () {
      expect(TodoRemindersFilter.medicine.showsReminders, isTrue);
      expect(TodoRemindersFilter.medicine.showsPlans, isFalse);
    });
  });

  group('plansListFilter', () {
    test('meals maps to meals filter', () {
      expect(TodoRemindersFilter.meals.plansListFilter, PlansFilter.meals);
    });

    test('subscriptions has no plans filter', () {
      expect(TodoRemindersFilter.subscriptions.plansListFilter, isNull);
    });
  });

  group('filterReminders', () {
    final items = [
      _reminder(ReminderSourceType.plan, id: 'p'),
      _reminder(ReminderSourceType.medicine, id: 'm'),
      _reminder(ReminderSourceType.subscription, id: 's'),
      _reminder(ReminderSourceType.standalone, id: 'c'),
    ];

    test('all excludes plan reminders', () {
      final filtered = TodoRemindersFilter.all.filterReminders(items);
      expect(filtered.every((i) => i.sourceType != ReminderSourceType.plan),
          isTrue);
      expect(filtered, hasLength(3));
    });

    test('medicine keeps medicine only', () {
      final filtered = TodoRemindersFilter.medicine.filterReminders(items);
      expect(filtered, hasLength(1));
      expect(filtered.single.sourceType, ReminderSourceType.medicine);
    });

    test('custom keeps standalone only', () {
      final filtered = TodoRemindersFilter.custom.filterReminders(items);
      expect(filtered.single.sourceType, ReminderSourceType.standalone);
    });

    test('plans filter returns empty reminders list', () {
      expect(TodoRemindersFilter.plans.filterReminders(items), isEmpty);
    });
  });
}
