import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/plans/utils/reminder_section_grouper.dart';
import 'package:myplanr/shared/models/app_reminder_item.dart';

AppReminderItem reminder({
  required String id,
  DateTime? at,
  bool repeating = false,
}) {
  return AppReminderItem(
    id: id,
    sourceType: ReminderSourceType.standalone,
    sourceId: id,
    title: 'Reminder $id',
    reminderAt: at,
    isRepeating: repeating,
    timeLabel: repeating ? '08:00' : null,
  );
}

void main() {
  final now = DateTime(2025, 6, 15, 10);

  group('groupRemindersIntoSections', () {
    test('returns empty for no items', () {
      expect(groupRemindersIntoSections([], now: now), isEmpty);
    });

    test('groups overdue, today, upcoming, and daily', () {
      final sections = groupRemindersIntoSections(
        [
          reminder(id: 'o1', at: now.subtract(const Duration(days: 1))),
          reminder(id: 't1', at: now),
          reminder(id: 'u1', at: now.add(const Duration(days: 2))),
          reminder(id: 'd1', repeating: true),
        ],
        now: now,
      );

      expect(sections, hasLength(4));
      expect(sections[0].title, AppStrings.remindersSectionOverdue);
      expect(sections[0].items.single.id, 'o1');
      expect(sections[1].title, AppStrings.remindersSectionToday);
      expect(sections[2].title, AppStrings.remindersSectionUpcoming);
      expect(sections[3].title, AppStrings.remindersSectionDaily);
      expect(sections[3].items.single.isRepeating, isTrue);
    });

    test('skips one-off reminders without reminderAt', () {
      final sections = groupRemindersIntoSections(
        [reminder(id: 'missing')],
        now: now,
      );
      expect(sections, isEmpty);
    });
  });
}
