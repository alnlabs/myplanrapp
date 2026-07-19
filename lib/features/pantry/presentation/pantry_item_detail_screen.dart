import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/pantry_availability.dart';
import '../../../shared/models/pantry_item.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/pantry_availability_chips.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/pantry_repository.dart';
import '../data/pantry_shop_refresh.dart';
import '../../shopping/data/shopping_repository.dart';
import 'pantry_item_form_screen.dart';
import 'pantry_screen.dart';

class PantryItemDetailScreen extends ConsumerStatefulWidget {
  const PantryItemDetailScreen({super.key, required this.item});

  final PantryItem item;

  @override
  ConsumerState<PantryItemDetailScreen> createState() =>
      _PantryItemDetailScreenState();
}

class _PantryItemDetailScreenState
    extends ConsumerState<PantryItemDetailScreen> {
  // Optimistic status so the dropdown reflects the choice instantly instead of
  // waiting for the network round-trip + refetch.
  String? _statusOverride;
  bool _hasOverride = false;

  PantryItem get item => widget.item;

  PantryItem _currentItem() {
    return ref.watch(pantryItemProvider(item.id)).valueOrNull ?? item;
  }

  Future<void> _delete(BuildContext context) async {
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

  Future<void> _updateAvailability(String? status) async {
    final current = _currentItem();
    final previous = current.availabilityStatus;

    // Reflect the choice immediately.
    setState(() {
      _statusOverride = status;
      _hasOverride = true;
    });

    try {
      await ref.read(pantryRepositoryProvider).updateAvailabilityStatus(
            item.id,
            status,
          );
      if (status == PantryAvailability.fine) {
        await ref
            .read(shoppingRepositoryProvider)
            .removeLowStockShopItemsForPantry(
              householdId: current.householdId,
              pantryItemId: current.id,
              name: current.name,
            );
      }
      if (mounted) {
        showSuccessSnackBar(context, AppStrings.availabilityUpdated);
      }
      // Sync caches in the background; the UI already shows the new value.
      ref.invalidate(pantryItemProvider(item.id));
      unawaited(refreshPantryAndShop(ref));
      await ref.read(pantryItemProvider(item.id).future);
      if (mounted) setState(() => _hasOverride = false);
    } catch (e) {
      // Revert to the real value on failure.
      if (mounted) {
        setState(() {
          _statusOverride = previous;
          _hasOverride = false;
        });
        showSuccessSnackBar(context, AppStrings.errorGeneric);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentItem();
    final displayStatus =
        _hasOverride ? _statusOverride : current.availabilityStatus;
    final availabilityChip = StatusChip.forAvailability(displayStatus);

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
                if (context.mounted) Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: () => _delete(context),
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
                    selected: displayStatus,
                    onSelected: _updateAvailability,
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
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
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
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text(AppStrings.restockItem),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
