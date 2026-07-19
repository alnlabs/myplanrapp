import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/pantry_availability.dart';
import '../../../shared/constants/pantry_constants.dart';
import '../../../shared/models/pantry_item.dart';
import '../../../shared/providers/multi_select_provider.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/providers/list_display_mode_provider.dart';
import '../../../shared/widgets/compact_grid_card.dart';
import '../../../shared/widgets/list_grid_layout.dart';
import '../../../shared/widgets/paginated_list_footer.dart';
import '../../pantry/data/pantry_items_list_provider.dart';
import '../../pantry/presentation/pantry_item_detail_screen.dart';

class PantryListTab extends ConsumerWidget {
  const PantryListTab({super.key, required this.query, this.category});

  final String query;

  /// When set, only items in this pantry category are shown (null = all).
  final String? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(pantryItemsListProvider);
    final viewMode = ref.watch(listDisplayModeProvider(ListDisplayModeKeys.pantry));

    if (listState.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (listState.hasError) {
      return ErrorView(
        error: listState.error!,
        message: ApiErrorFormatter.format(listState.error!),
        onRetry: () => ref.read(pantryItemsListProvider.notifier).refresh(),
      );
    }

    final filtered = _filter(listState.items);
    if (filtered.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EmptyState(
            icon: Icons.kitchen_outlined,
            title: AppStrings.emptyPantry,
            subtitle: AppStrings.emptyPantryHint,
            actionLabel: AppStrings.addItem,
            onAction: () => context.push('/pantry/add'),
          ),
        ],
      );
    }

    return PaginatedScrollListener(
      onLoadMore: () => ref.read(pantryItemsListProvider.notifier).loadMore(),
      child: viewMode == ListDisplayMode.list
          ? ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: filtered.length + 1,
              separatorBuilder: (_, index) =>
                  index < filtered.length - 1
                      ? const SizedBox(height: 8)
                      : const SizedBox.shrink(),
              itemBuilder: (context, index) {
                if (index >= filtered.length) {
                  return PaginatedListFooter(
                    state: listState,
                    onRetryLoadMore: () =>
                        ref.read(pantryItemsListProvider.notifier).loadMore(),
                  );
                }
                final item = filtered[index];
                return PantryListTile(
                  item: item,
                  onTap: () => _openItem(context, ref, item),
                  selectionKey: MultiSelectKeys.pantry,
                );
              },
            )
          : GridView.builder(
              padding: ListGridLayout.padding,
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: ListGridLayout.tabGridDelegate,
              itemCount: filtered.length + 1,
              itemBuilder: (context, index) {
                if (index >= filtered.length) {
                  return SizedBox(
                    height: 48,
                    child: Center(
                      child: PaginatedListFooter(
                        state: listState,
                        onRetryLoadMore: () => ref
                            .read(pantryItemsListProvider.notifier)
                            .loadMore(),
                      ),
                    ),
                  );
                }
                final item = filtered[index];
                return _PantryGridCard(
                  item: item,
                  onTap: () => _openItem(context, ref, item),
                  selectionKey: MultiSelectKeys.pantry,
                );
              },
            ),
    );
  }

  Future<void> _openItem(
    BuildContext context,
    WidgetRef ref,
    PantryItem item,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantryItemDetailScreen(item: item),
      ),
    );
  }

  List<PantryItem> _filter(List<PantryItem> items) =>
      filterPantryItems(items, query: query, category: category);
}

/// Shared pantry filter so the list tab and the inventory selection app bar
/// operate on the same visible set.
List<PantryItem> filterPantryItems(
  List<PantryItem> items, {
  required String query,
  String? category,
}) {
  return items.where((i) {
    if (category != null && i.category != category) return false;
    if (query.isEmpty) return true;
    return i.name.toLowerCase().contains(query) ||
        (i.brandLabel?.toLowerCase().contains(query) ?? false) ||
        (i.category?.toLowerCase().contains(query) ?? false);
  }).toList();
}

Color _pantryStatusColor(PantryItem item, ThemeData theme) {
  if (item.hasManualAttention) {
    return PantryAvailability.color(item.availabilityStatus!);
  }
  if (item.isOutOfStock) return theme.colorScheme.error;
  if (item.isLowStock) return Colors.orange.shade800;
  return theme.colorScheme.primary;
}

bool _showPantryStatusDot(PantryItem item) {
  return item.hasManualAttention || item.isOutOfStock || item.isLowStock;
}

String? _compactStatusLabel(PantryItem item) {
  if (item.isExplicitlyFine || !item.needsAttention) return null;
  return item.attentionLabel;
}

class PantryListTile extends ConsumerWidget {
  const PantryListTile({
    super.key,
    required this.item,
    required this.onTap,
    this.selectionKey,
  });

  final PantryItem item;
  final VoidCallback onTap;

  /// When set, long-press starts multi-select and taps toggle selection.
  final String? selectionKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColor = _pantryStatusColor(item, theme);
    final statusLabel = _compactStatusLabel(item);
    final subtitleParts = [
      Formatters.pantryItemSubtitle(
        quantity: item.quantity,
        unit: item.unit,
        brand: item.brandLabel,
      ),
      if (item.category != null) item.category!,
      if (statusLabel != null) statusLabel,
    ];

    final key = selectionKey;
    final selection = key != null ? ref.watch(multiSelectProvider(key)) : null;
    final notifier = key != null ? ref.read(multiSelectProvider(key).notifier) : null;
    final selecting = selection?.active ?? false;
    final selected = selection?.contains(item.id) ?? false;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: selected ? theme.colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: selecting ? () => notifier!.toggle(item.id) : onTap,
        onLongPress:
            (notifier != null && !selecting) ? () => notifier.enter(item.id) : null,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: selecting
              ? Checkbox(
                  value: selected,
                  onChanged: (_) => notifier!.toggle(item.id),
                )
              : Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: statusColor.withOpacity(0.14),
                      child: Icon(
                        PantryCategories.iconFor(item.category),
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    if (_showPantryStatusDot(item))
                      Positioned(
                        right: -1,
                        top: -1,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.surface,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
          title: Text(
            item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitleParts.join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: statusLabel != null
                  ? statusColor
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing:
              selecting ? null : const Icon(Icons.chevron_right, size: 20),
        ),
      ),
    );
  }
}

class _PantryGridCard extends ConsumerWidget {
  const _PantryGridCard({
    required this.item,
    required this.onTap,
    this.selectionKey,
  });

  final PantryItem item;
  final VoidCallback onTap;
  final String? selectionKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColor = _pantryStatusColor(item, theme);

    final key = selectionKey;
    final selection = key != null ? ref.watch(multiSelectProvider(key)) : null;
    final notifier = key != null ? ref.read(multiSelectProvider(key).notifier) : null;
    final selecting = selection?.active ?? false;
    final selected = selection?.contains(item.id) ?? false;

    return CompactGridCard(
      onTap: selecting ? () => notifier!.toggle(item.id) : onTap,
      onLongPress:
          (notifier != null && !selecting) ? () => notifier.enter(item.id) : null,
      selected: selected,
      leading: CompactGridIcon(
        icon: selecting
            ? (selected ? Icons.check_circle : Icons.circle_outlined)
            : PantryCategories.iconFor(item.category),
        color: statusColor,
        badgeColor: _showPantryStatusDot(item) ? statusColor : null,
      ),
      title: item.name,
      subtitle: Formatters.pantryItemSubtitle(
        quantity: item.quantity,
        unit: item.unit,
        brand: item.brandLabel,
      ),
    );
  }
}
