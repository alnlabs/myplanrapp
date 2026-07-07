import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/models/app_reminder_item.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../data/reminder_repository.dart';
import 'reminder_form_screen.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(appRemindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.remindersTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final saved = await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (_) => const ReminderFormScreen(),
            ),
          );
          if (saved == true) ref.invalidate(appRemindersProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addReminder),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(appRemindersProvider);
          await ref.read(appRemindersProvider.future);
        },
        child: AsyncScreenBody(
          value: remindersAsync,
          onRetry: () => ref.invalidate(appRemindersProvider),
          isEmpty: (items) => items.isEmpty,
          emptyIcon: Icons.notifications_outlined,
          emptyTitle: AppStrings.emptyReminders,
          emptySubtitle: AppStrings.emptyRemindersHint,
          emptyActionLabel: AppStrings.addReminder,
          onEmptyAction: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ReminderFormScreen(),
            ),
          ),
          builder: (items) => _GroupedRemindersList(
            items: items,
            onEdit: (item) => _editReminder(context, ref, item),
            onDelete: (item) => _deleteReminder(context, ref, item),
          ),
        ),
      ),
    );
  }

  Future<void> _editReminder(
    BuildContext context,
    WidgetRef ref,
    AppReminderItem item,
  ) async {
    if (item.isStandalone) {
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => ReminderFormScreen(standaloneId: item.sourceId),
        ),
      );
      if (saved == true) ref.invalidate(appRemindersProvider);
      return;
    }

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ReminderFormScreen(linkedItem: item),
      ),
    );
    if (saved == true) ref.invalidate(appRemindersProvider);
  }

  Future<void> _deleteReminder(
    BuildContext context,
    WidgetRef ref,
    AppReminderItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.reminderDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(reminderRepositoryProvider).removeLinkedReminder(item);
    ref.invalidate(appRemindersProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.reminderDeleted)),
      );
    }
  }
}

class _GroupedRemindersList extends StatelessWidget {
  const _GroupedRemindersList({
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  final List<AppReminderItem> items;
  final ValueChanged<AppReminderItem> onEdit;
  final ValueChanged<AppReminderItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
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

    final sections = <({String title, List<AppReminderItem> items})>[
      if (overdue.isNotEmpty) (title: AppStrings.remindersSectionOverdue, items: overdue),
      if (todayItems.isNotEmpty) (title: AppStrings.remindersSectionToday, items: todayItems),
      if (upcoming.isNotEmpty) (title: AppStrings.remindersSectionUpcoming, items: upcoming),
      if (daily.isNotEmpty) (title: AppStrings.remindersSectionDaily, items: daily),
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        return Padding(
          padding: EdgeInsets.only(bottom: index == sections.length - 1 ? 0 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              ...section.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ReminderTile(
                    item: item,
                    onTap: () => onEdit(item),
                    onDelete: () => onDelete(item),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final AppReminderItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _colorFor(item.sourceType, theme);
    final whenText = item.isRepeating
        ? item.timeLabel ?? AppStrings.reminderRepeatingDaily
        : item.reminderAt != null
            ? Formatters.dateTime(item.reminderAt!.toLocal())
            : '—';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.14),
                child: Icon(_iconFor(item.sourceType), color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle ?? _sourceLabel(item.sourceType),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          item.isRepeating
                              ? Icons.repeat
                              : Icons.schedule_outlined,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            whenText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                tooltip: AppStrings.delete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _sourceLabel(ReminderSourceType type) {
    return switch (type) {
      ReminderSourceType.plan => AppStrings.reminderSourcePlan,
      ReminderSourceType.subscription => AppStrings.reminderSourceSubscription,
      ReminderSourceType.medicine => AppStrings.reminderSourceMedicine,
      ReminderSourceType.standalone => AppStrings.reminderSourceStandalone,
    };
  }

  IconData _iconFor(ReminderSourceType type) {
    return switch (type) {
      ReminderSourceType.plan => Icons.event_note_outlined,
      ReminderSourceType.subscription => Icons.subscriptions_outlined,
      ReminderSourceType.medicine => Icons.medication_outlined,
      ReminderSourceType.standalone => Icons.notifications_outlined,
    };
  }

  Color _colorFor(ReminderSourceType type, ThemeData theme) {
    return switch (type) {
      ReminderSourceType.plan => theme.colorScheme.primary,
      ReminderSourceType.subscription => Colors.deepOrange,
      ReminderSourceType.medicine => Colors.teal,
      ReminderSourceType.standalone => theme.colorScheme.secondary,
    };
  }
}
