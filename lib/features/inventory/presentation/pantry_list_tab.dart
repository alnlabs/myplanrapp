import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
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
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = filtered[index];
            return Card(
              child: ListTile(
                title: Text(item.name),
                subtitle: Text(Formatters.quantity(item.quantity, item.unit)),
                trailing: item.isOutOfStock
                    ? const StatusChip(type: StatusChipType.outOfStock)
                    : item.isLowStock
                        ? const StatusChip(type: StatusChipType.lowStock)
                        : null,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PantryItemDetailScreen(item: item),
                    ),
                  );
                  ref.invalidate(pantryItemsProvider);
                  ref.invalidate(lowStockItemsProvider);
                },
              ),
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
              (i.category?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }
}
