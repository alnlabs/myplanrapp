import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/models/pantry_item.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/pantry_repository.dart';
import 'pantry_item_form_screen.dart';
import 'pantry_screen.dart';

class PantryItemDetailScreen extends ConsumerWidget {
  const PantryItemDetailScreen({super.key, required this.item});

  final PantryItem item;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.delete,
      message: AppStrings.confirmDelete,
    );
    if (confirmed != true) return;
    await ref.read(pantryRepositoryProvider).deleteItem(item.id);
    ref.invalidate(pantryItemsProvider);
    ref.invalidate(lowStockItemsProvider);
    ref.invalidate(expiringItemsProvider);
    if (context.mounted) {
      Navigator.pop(context);
      showSuccessSnackBar(context, AppStrings.itemDeleted);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(stockEventsProvider(item.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PantryItemFormScreen(item: item),
                ),
              );
              if (context.mounted) Navigator.pop(context);
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
                    Formatters.quantity(item.quantity, item.unit),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (item.category != null) ...[
                    const SizedBox(height: 8),
                    Text(item.category!),
                  ],
                  if (item.expiryDate != null) ...[
                    const SizedBox(height: 8),
                    Text('${AppStrings.expiryDate}: ${Formatters.date(item.expiryDate!)}'),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (item.isOutOfStock)
                        const StatusChip(type: StatusChipType.outOfStock)
                      else if (item.isLowStock)
                        const StatusChip(type: StatusChipType.lowStock),
                      if (item.isExpired)
                        const StatusChip(type: StatusChipType.missing)
                      else if (item.isExpiringSoon)
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
                  onPressed: () => showStockSheet(context, ref, item: item, isRestock: false),
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text(AppStrings.useItem),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => showStockSheet(context, ref, item: item, isRestock: true),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text(AppStrings.restockItem),
                ),
              ),
            ],
          ),
          const SectionHeader(title: AppStrings.stockHistory),
          AsyncScreenBody(
            value: eventsAsync,
            onRetry: () => ref.invalidate(stockEventsProvider(item.id)),
            isEmpty: (events) => events.isEmpty,
            emptyTitle: 'No history yet',
            builder: (events) {
              return Column(
                children: events.map((event) {
                  final sign = event.delta >= 0 ? '+' : '';
                  return Card(
                    child: ListTile(
                      title: Text('$sign${event.delta} ${item.unit}'),
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
