import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../pantry/data/pantry_repository.dart';
import '../../shopping/data/shopping_repository.dart';
import '../services/notification_service.dart';

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
          emptyTitle: AppStrings.emptyAlerts,
          emptySubtitle: AppStrings.emptyAlertsHint,
          builder: (items) {
            for (final item in items) {
              NotificationService.instance.showLowStockAlert(
                itemId: item.id,
                title: AppStrings.alertsTitle,
                body: '${item.name} is running low (${Formatters.quantity(item.quantity, item.unit)} left)',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text(Formatters.quantity(item.quantity, item.unit)),
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
