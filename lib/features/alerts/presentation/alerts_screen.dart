import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../pantry/data/pantry_repository.dart';
import '../../shopping/data/shopping_repository.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowStockAsync = ref.watch(lowStockItemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.alertsTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(lowStockItemsProvider);
          await ref.read(lowStockItemsProvider.future);
        },
        child: AsyncScreenBody(
          value: lowStockAsync,
          onRetry: () => ref.invalidate(lowStockItemsProvider),
          isEmpty: (items) => items.isEmpty,
          emptyIcon: Icons.inventory_2_outlined,
          emptyTitle: AppStrings.emptyAlerts,
          emptySubtitle: AppStrings.emptyAlertsHint,
          builder: (items) {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    title: Text(
                      item.brandLabel != null
                          ? '${item.name} (${item.brandLabel})'
                          : item.name,
                    ),
                    subtitle: Text(
                      item.lowStockThreshold != null
                          ? '${Formatters.quantity(item.quantity, item.unit)} · ${AppStrings.lowStockAlert} ${Formatters.quantity(item.lowStockThreshold!, item.effectiveLowStockUnit)}'
                          : Formatters.quantity(item.quantity, item.unit),
                    ),
                    trailing: item.isOutOfStock
                        ? const StatusChip(type: StatusChipType.outOfStock)
                        : const StatusChip(type: StatusChipType.lowStock),
                    onTap: () async {
                      await ref
                          .read(shoppingRepositoryProvider)
                          .generateFromLowStock(item.householdId);
                      ref.invalidate(shoppingListProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text(AppStrings.addToShopList)),
                        );
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
