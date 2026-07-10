import 'package:flutter/material.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/models/app_reminder_item.dart';
import '../../../shared/widgets/compact_grid_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/list_grid_layout.dart';
import '../../../shared/utils/formatters.dart';
import '../utils/reminder_section_grouper.dart';

class ReminderListSections extends StatelessWidget {
  const ReminderListSections({
    super.key,
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  final List<AppReminderItem> items;
  final ValueChanged<AppReminderItem> onEdit;
  final ValueChanged<AppReminderItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final sections = groupRemindersIntoSections(items);
    if (sections.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i == 0) const SizedBox(height: 8),
          Text(
            sections[i].title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          ...sections[i].items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ReminderListTile(
                item: item,
                onTap: () => onEdit(item),
                onDelete: () => onDelete(item),
              ),
            ),
          ),
          if (i < sections.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

List<({String title, List<AppReminderItem> items})> _groupedSections(
  List<AppReminderItem> items,
) {
  return groupRemindersIntoSections(items)
      .map((section) => (title: section.title, items: section.items))
      .toList();
}

class GroupedRemindersList extends StatelessWidget {
  const GroupedRemindersList({
    super.key,
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  final List<AppReminderItem> items;
  final ValueChanged<AppReminderItem> onEdit;
  final ValueChanged<AppReminderItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final sections = groupRemindersIntoSections(items);

    if (sections.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EmptyState(
            icon: Icons.notifications_outlined,
            title: AppStrings.emptyFilteredReminders,
            subtitle: AppStrings.emptyRemindersHint,
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        return Padding(
          padding:
              EdgeInsets.only(bottom: index == sections.length - 1 ? 0 : 20),
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
                  child: ReminderListTile(
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

class RemindersGrid extends StatelessWidget {
  const RemindersGrid({
    super.key,
    required this.items,
    required this.onEdit,
  });

  final List<AppReminderItem> items;
  final ValueChanged<AppReminderItem> onEdit;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EmptyState(
            icon: Icons.notifications_outlined,
            title: AppStrings.emptyFilteredReminders,
            subtitle: AppStrings.emptyRemindersHint,
          ),
        ],
      );
    }

    return GridView.builder(
      padding: ListGridLayout.padding,
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: ListGridLayout.gridDelegate,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ReminderGridCard(item: item, onTap: () => onEdit(item));
      },
    );
  }
}

class ReminderGridCard extends StatelessWidget {
  const ReminderGridCard({super.key, required this.item, required this.onTap});

  final AppReminderItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = reminderColorFor(item.sourceType, theme);
    final whenText = item.isRepeating
        ? item.timeLabel ?? AppStrings.reminderRepeatingDaily
        : item.reminderAt != null
            ? Formatters.dateTime(item.reminderAt!.toLocal())
            : '—';

    return CompactGridCard(
      onTap: onTap,
      leading: CompactGridIcon(
        icon: reminderIconFor(item.sourceType),
        color: color,
      ),
      title: item.title,
      subtitle: _reminderCardSubtitle(item, whenText),
    );
  }
}

String _reminderCardSubtitle(AppReminderItem item, String whenText) {
  final parts = <String>[
    if (item.notes != null && item.notes!.trim().isNotEmpty) item.notes!.trim(),
    whenText,
  ];
  return parts.join(' · ');
}

class ReminderListTile extends StatelessWidget {
  const ReminderListTile({
    super.key,
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
    final color = reminderColorFor(item.sourceType, theme);
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
                child: Icon(
                  reminderIconFor(item.sourceType),
                  color: color,
                  size: 20,
                ),
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
                      item.subtitle ?? reminderSourceLabel(item.sourceType),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.notes!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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
}

String reminderSourceLabel(ReminderSourceType type) {
  return switch (type) {
    ReminderSourceType.plan => AppStrings.reminderSourcePlan,
    ReminderSourceType.subscription => AppStrings.reminderSourceSubscription,
    ReminderSourceType.medicine => AppStrings.reminderSourceMedicine,
    ReminderSourceType.standalone => AppStrings.reminderSourceStandalone,
  };
}

IconData reminderIconFor(ReminderSourceType type) {
  return switch (type) {
    ReminderSourceType.plan => Icons.event_note_outlined,
    ReminderSourceType.subscription => Icons.subscriptions_outlined,
    ReminderSourceType.medicine => Icons.medication_outlined,
    ReminderSourceType.standalone => Icons.notifications_outlined,
  };
}

Color reminderColorFor(ReminderSourceType type, ThemeData theme) {
  return switch (type) {
    ReminderSourceType.plan => theme.colorScheme.primary,
    ReminderSourceType.subscription => Colors.deepOrange,
    ReminderSourceType.medicine => Colors.teal,
    ReminderSourceType.standalone => theme.colorScheme.secondary,
  };
}
