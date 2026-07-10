import '../../../core/strings/app_strings.dart';
import '../../../shared/models/app_reminder_item.dart';

class ReminderSection {
  const ReminderSection({required this.title, required this.items});

  final String title;
  final List<AppReminderItem> items;
}

/// Groups reminders into overdue / today / upcoming / daily sections.
List<ReminderSection> groupRemindersIntoSections(
  List<AppReminderItem> items, {
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final tomorrow = today.add(const Duration(days: 1));

  final overdue = <AppReminderItem>[];
  final todayItems = <AppReminderItem>[];
  final upcoming = <AppReminderItem>[];
  final daily = <AppReminderItem>[];

  for (final item in items) {
    if (item.isRepeating) {
      daily.add(item);
      continue;
    }
    final at = item.reminderAt;
    if (at == null) continue;
    final local = at.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    if (day.isBefore(today)) {
      overdue.add(item);
    } else if (day.isBefore(tomorrow)) {
      todayItems.add(item);
    } else {
      upcoming.add(item);
    }
  }

  return [
    if (overdue.isNotEmpty)
      ReminderSection(title: AppStrings.remindersSectionOverdue, items: overdue),
    if (todayItems.isNotEmpty)
      ReminderSection(title: AppStrings.remindersSectionToday, items: todayItems),
    if (upcoming.isNotEmpty)
      ReminderSection(
        title: AppStrings.remindersSectionUpcoming,
        items: upcoming,
      ),
    if (daily.isNotEmpty)
      ReminderSection(title: AppStrings.remindersSectionDaily, items: daily),
  ];
}
