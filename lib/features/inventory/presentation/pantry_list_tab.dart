import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/pantry_constants.dart';
import '../../../shared/models/pantry_item.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../pantry/data/pantry_repository.dart';
import '../../pantry/presentation/pantry_item_detail_screen.dart';

class PantryListTab extends ConsumerWidget {
  const PantryListTab({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(pantryItemsProvider);

    return AsyncScreenBody(
      value: itemsAsync,
      onRetry: () => ref.invalidate(pantryItemsProvider),
      isEmpty: (items) => _filter(items).isEmpty,
      emptyTitle: AppStrings.emptyPantry,
      emptySubtitle: AppStrings.emptyPantryHint,
      emptyActionLabel: AppStrings.addItem,
      onEmptyAction: () => context.push('/pantry/add'),
      builder: (items) {
        final filtered = _filter(items);
        if (filtered.isEmpty) {
          return ListView(
            children: const [
              SizedBox(height: 64),
              Center(child: Text(AppStrings.emptyPantry)),
            ],
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.35,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final item = filtered[index];
            return _PantryGridCard(
              item: item,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PantryItemDetailScreen(item: item),
                  ),
                );
                ref.invalidate(pantryItemsProvider);
                ref.invalidate(lowStockItemsProvider);
              },
            );
          },
        );
      },
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

class _PantryGridCard extends StatelessWidget {
  const _PantryGridCard({required this.item, required this.onTap});

  final PantryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = item.isOutOfStock
        ? theme.colorScheme.error
        : item.isLowStock
            ? Colors.orange.shade800
            : theme.colorScheme.primary;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: statusColor.withOpacity(0.14),
                    child: Icon(
                      PantryCategories.iconFor(item.category),
                      color: statusColor,
                      size: 18,
                    ),
                  ),
                  if (item.isOutOfStock)
                    const StatusChip(type: StatusChipType.outOfStock)
                  else if (item.isLowStock)
                    const StatusChip(type: StatusChipType.lowStock),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Formatters.pantryItemSubtitle(
                      quantity: item.quantity,
                      unit: item.unit,
                      brand: item.brandLabel,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
