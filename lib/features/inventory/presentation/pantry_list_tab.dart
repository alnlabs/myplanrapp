import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/pantry_availability.dart';
import '../../../shared/constants/pantry_constants.dart';
import '../../../shared/models/pantry_item.dart';
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
  const PantryListTab({super.key, required this.query});

  final String query;

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
                return _PantryListTile(
                  item: item,
                  onTap: () => _openItem(context, ref, item),
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

  List<PantryItem> _filter(List<PantryItem> items) {
    if (query.isEmpty) return items;
    return items
        .where(
          (i) =>
              i.name.toLowerCase().contains(query) ||
              (i.brandLabel?.toLowerCase().contains(query) ?? false) ||
              (i.category?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }
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

class _PantryListTile extends StatelessWidget {
  const _PantryListTile({required this.item, required this.onTap});

  final PantryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Stack(
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
            maxLines: 1,
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
          trailing: const Icon(Icons.chevron_right, size: 20),
        ),
      ),
    );
  }
}

class _PantryGridCard extends StatelessWidget {
  const _PantryGridCard({required this.item, required this.onTap});

  final PantryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _pantryStatusColor(item, theme);

    return CompactGridCard(
      onTap: onTap,
      leading: CompactGridIcon(
        icon: PantryCategories.iconFor(item.category),
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
