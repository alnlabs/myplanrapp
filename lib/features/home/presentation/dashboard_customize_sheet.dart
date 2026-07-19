import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/utils/app_bottom_sheet.dart';
import '../data/dashboard_layout_provider.dart';

/// Bottom sheet to reorder dashboard cards and toggle their visibility.
Future<void> showDashboardCustomizeSheet(BuildContext context) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _DashboardCustomizeSheet(),
  );
}

class _DashboardCustomizeSheet extends ConsumerWidget {
  const _DashboardCustomizeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final layout = ref.watch(dashboardLayoutProvider);
    final notifier = ref.read(dashboardLayoutProvider.notifier);
    final order = layout.order;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              child: Text(
                AppStrings.customizeDashboard,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text(
                AppStrings.customizeDashboardHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Flexible(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                itemCount: order.length,
                onReorder: (oldIndex, newIndex) {
                  final next = [...order];
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = next.removeAt(oldIndex);
                  next.insert(newIndex, item);
                  notifier.reorder(next);
                },
                itemBuilder: (context, index) {
                  final id = order[index];
                  final visible = layout.isVisible(id);
                  return Padding(
                    key: ValueKey(id),
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.4),
                      child: ListTile(
                        leading: ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_handle),
                        ),
                        title: Text(id.label),
                        trailing: Switch(
                          value: visible,
                          onChanged: (value) => notifier.setVisible(id, value),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
