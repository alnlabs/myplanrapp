import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/pantry_availability.dart';
import '../../../shared/models/pantry_item.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../../../shared/widgets/pantry_availability_chips.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/pantry_repository.dart';
import '../data/pantry_shop_refresh.dart';
import '../../shopping/data/shopping_repository.dart';
import 'pantry_item_form_screen.dart';
import 'pantry_screen.dart';

class PantryItemDetailScreen extends ConsumerWidget {
  const PantryItemDetailScreen({super.key, required this.item});

  final PantryItem item;

  PantryItem _currentItem(WidgetRef ref) {
    return ref.watch(pantryItemProvider(item.id)).valueOrNull ?? item;
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.delete,
      message: AppStrings.confirmDelete,
    );
    if (confirmed != true) return;
    await ref.read(pantryRepositoryProvider).deleteItem(item.id);
    await refreshPantryListAndAlerts(ref);
    if (context.mounted) {
      Navigator.pop(context);
      showSuccessSnackBar(context, AppStrings.itemDeleted);
    }
  }

  Future<void> _updateAvailability(
    BuildContext context,
    WidgetRef ref,
    String? status,
  ) async {
    await ref.read(pantryRepositoryProvider).updateAvailabilityStatus(
          item.id,
          status,
        );
    final current = _currentItem(ref);
    if (status == PantryAvailability.fine) {
      await ref.read(shoppingRepositoryProvider).removeLowStockShopItemsForPantry(
            householdId: current.householdId,
            pantryItemId: current.id,
            name: current.name,
          );
    }
    await refreshPantryAndShop(ref);
    if (context.mounted) {
      showSuccessSnackBar(context, AppStrings.availabilityUpdated);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = _currentItem(ref);
    final eventsAsync = ref.watch(stockEventsProvider(current.id));
    final availabilityChip = StatusChip.forAvailability(current.availabilityStatus);

    return Scaffold(
      appBar: AppBar(
        title: Text(current.name),
        actions: [
          IconButton(
            onPressed: () async {
              final updated = await Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(
                  builder: (_) => PantryItemFormScreen(item: current),
                ),
              );
              if (updated == true && context.mounted) {
                ref.invalidate(pantryItemProvider(current.id));
                await refreshPantryListAndAlerts(ref);
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: () => _delete(context, ref),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Formatters.quantity(current.quantity, current.unit),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (current.brandLabel != null) ...[
                    const SizedBox(height: 8),
                    Text('${AppStrings.brand}: ${current.brandLabel}'),
                  ],
                  if (current.category != null) ...[
                    const SizedBox(height: 8),
                    Text(current.category!),
                  ],
                  if (current.expiryDate != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${AppStrings.expiryDate}: ${Formatters.date(current.expiryDate!)}',
                    ),
                  ],
                  const SizedBox(height: 16),
                  PantryAvailabilityChips(
                    selected: current.availabilityStatus,
                    onSelected: (status) =>
                        _updateAvailability(context, ref, status),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (current.hasManualAttention && availabilityChip != null)
                        StatusChip(type: availabilityChip),
                      if (current.isOutOfStock)
                        const StatusChip(type: StatusChipType.outOfStock)
                      else if (current.isLowStock)
                        const StatusChip(type: StatusChipType.lowStock),
                      if (current.isExpired)
                        const StatusChip(type: StatusChipType.missing)
                      else if (current.isExpiringSoon)
                        const StatusChip(type: StatusChipType.lowStock),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showStockSheet(
                    context,
                    ref,
                    item: current,
                    isRestock: false,
                  ),
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text(AppStrings.useItem),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => showStockSheet(
                    context,
                    ref,
                    item: current,
                    isRestock: true,
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text(AppStrings.restockItem),
                ),
              ),
            ],
          ),
          const SectionHeader(title: AppStrings.stockHistory),
          AsyncScreenBody(
            value: eventsAsync,
            onRetry: () => ref.invalidate(stockEventsProvider(current.id)),
            isEmpty: (events) => events.isEmpty,
            emptyTitle: AppStrings.emptyStockHistory,
            builder: (events) {
              return Column(
                children: events.map((event) {
                  final sign = event.delta >= 0 ? '+' : '';
                  return Card(
                    child: ListTile(
                      title: Text('$sign${event.delta} ${current.unit}'),
                      subtitle: Text(event.note ?? event.reason),
                      trailing: Text(
                        DateFormat('d MMM, h:mm a').format(event.createdAt.toLocal()),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
