import '../../../shared/models/app_reminder_item.dart';
import 'plans_filter.dart';

/// Filters for the unified To-do & reminders screen.
enum TodoRemindersFilter {
  all,
  plans,
  meals,
  reminders,
  medicine,
  subscriptions,
  custom;

  static TodoRemindersFilter? fromQuery(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final filter in TodoRemindersFilter.values) {
      if (filter.name == value) return filter;
    }
    return null;
  }
}

extension TodoRemindersFilterX on TodoRemindersFilter {
  bool get showsPlans =>
      this == TodoRemindersFilter.all ||
      this == TodoRemindersFilter.plans ||
      this == TodoRemindersFilter.meals;

  bool get showsReminders =>
      this == TodoRemindersFilter.all ||
      this == TodoRemindersFilter.reminders ||
      this == TodoRemindersFilter.medicine ||
      this == TodoRemindersFilter.subscriptions ||
      this == TodoRemindersFilter.custom;

  PlansFilter? get plansListFilter => switch (this) {
        TodoRemindersFilter.meals => PlansFilter.meals,
        TodoRemindersFilter.all || TodoRemindersFilter.plans => PlansFilter.all,
        _ => null,
      };

  List<AppReminderItem> filterReminders(List<AppReminderItem> items) {
    return switch (this) {
      TodoRemindersFilter.all => items
          .where((item) => item.sourceType != ReminderSourceType.plan)
          .toList(),
      TodoRemindersFilter.reminders => items,
      TodoRemindersFilter.medicine => items
          .where((item) => item.sourceType == ReminderSourceType.medicine)
          .toList(),
      TodoRemindersFilter.subscriptions => items
          .where(
            (item) => item.sourceType == ReminderSourceType.subscription,
          )
          .toList(),
      TodoRemindersFilter.custom => items
          .where((item) => item.sourceType == ReminderSourceType.standalone)
          .toList(),
      _ => const [],
    };
  }
}
