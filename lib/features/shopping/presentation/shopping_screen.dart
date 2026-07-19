import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/models/shopping_list_item.dart';
import '../../../shared/providers/multi_select_provider.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/utils/list_sharing.dart';
import '../../../shared/widgets/feature_screen_app_bar.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../../../shared/widgets/restock_amount_sheet.dart';
import '../../../shared/widgets/selection_app_bar.dart';
import '../../auth/data/auth_repository.dart';
import '../../pantry/data/pantry_items_list_provider.dart';
import '../../pantry/data/pantry_repository.dart';
import '../data/shopping_list_provider.dart';
import '../data/shopping_repository.dart';

enum _ShopMenuAction { shareList }

class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  final _nameController = TextEditingController();
  bool _restockOnBuy = true;
  bool _initialShopSyncDone = false;
  // Items removed optimistically while the buy completes in the background.
  final Set<String> _hiddenIds = {};

  void _hide(String id) => setState(() => _hiddenIds.add(id));
  void _unhide(String id) => setState(() => _hiddenIds.remove(id));

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<String?> _householdId() async {
    final profile = await ref.read(userProfileProvider.future);
    return profile?.activeHouseholdId;
  }

  Future<void> _addManual() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final householdId = await _householdId();
    if (householdId == null) return;
    await ref.read(shoppingRepositoryProvider).addItem(
          householdId: householdId,
          name: name,
        );
    _nameController.clear();
    ref.invalidate(shoppingListProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.itemAdded)),
      );
    }
  }

  Future<void> _shareList(List<ShoppingListItem> items) async {
    if (items.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.emptyShop)),
        );
      }
      return;
    }

    final text = formatShopListForSharing(
      title: AppStrings.shopListShareTitle(items.length),
      itemNames: items.map((item) {
        final quantity = (item.quantity != null && item.unit != null)
            ? ' (${Formatters.quantity(item.quantity!, item.unit!)})'
            : '';
        return '${item.name}$quantity';
      }).toList(),
    );

    await showShareShopListSheet(context, text: text);
  }

  Future<void> _deleteSelected() async {
    final notifier =
        ref.read(multiSelectProvider(MultiSelectKeys.shopping).notifier);
    final ids =
        ref.read(multiSelectProvider(MultiSelectKeys.shopping)).ids.toList();
    if (ids.isEmpty) return;
    final confirmed = await confirmBulkDelete(context, ids.length);
    if (!confirmed) return;
    final repo = ref.read(shoppingRepositoryProvider);
    for (final id in ids) {
      await repo.deleteItem(id);
    }
    notifier.clear();
    ref.invalidate(shoppingListProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.itemsDeleted(ids.length))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialShopSyncDone) {
      _initialShopSyncDone = true;
      Future.microtask(() => refreshShopFromPantry(ref));
    }

    final itemsAsync = ref.watch(shoppingListProvider);
    final items = itemsAsync.valueOrNull ?? [];
    final visibleItems =
        items.where((i) => !_hiddenIds.contains(i.id)).toList();
    final hasItems = items.isNotEmpty;
    final selection = ref.watch(multiSelectProvider(MultiSelectKeys.shopping));

    return Scaffold(
      appBar: selection.active
          ? SelectionAppBar(
              selectedCount: selection.count,
              totalCount: visibleItems.length,
              onClose: () => ref
                  .read(multiSelectProvider(MultiSelectKeys.shopping).notifier)
                  .clear(),
              onSelectAll: () {
                final notifier = ref.read(
                    multiSelectProvider(MultiSelectKeys.shopping).notifier);
                if (selection.count >= visibleItems.length) {
                  notifier.selectAll(const []);
                } else {
                  notifier.selectAll(visibleItems.map((e) => e.id));
                }
              },
              onDelete: () => _deleteSelected(),
            )
          : FeatureScreenAppBar.forShellRoute(
        context,
        title: AppStrings.shopTitle,
        subtitle: AppStrings.shopSubtitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: AppStrings.shareShopList,
            onPressed: hasItems ? () => _shareList(items) : null,
          ),
          PopupMenuButton<_ShopMenuAction>(
            onSelected: (action) {
              switch (action) {
                case _ShopMenuAction.shareList:
                  _shareList(items);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _ShopMenuAction.shareList,
                enabled: hasItems,
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.share_outlined),
                  title: Text(AppStrings.shareShopList),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _AddItemBar(
            controller: _nameController,
            onAdd: _addManual,
          ),
          _RestockToggle(
            value: _restockOnBuy,
            onChanged: (v) => setState(() => _restockOnBuy = v),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final profile = await ref.read(userProfileProvider.future);
                final householdId = profile?.activeHouseholdId;
                if (householdId != null) {
                  await ref
                      .read(shoppingRepositoryProvider)
                      .syncLowStockToShop(householdId);
                }
                ref.invalidate(shoppingListProvider);
                await ref.read(shoppingListProvider.future);
              },
              child: AsyncScreenBody(
                value: itemsAsync,
                onRetry: () => ref.invalidate(shoppingListProvider),
                isEmpty: (items) => items.isEmpty,
                emptyIcon: Icons.shopping_cart_outlined,
                emptyTitle: AppStrings.emptyShop,
                emptySubtitle: AppStrings.emptyShopHint,
                builder: (items) => _ShoppingList(
                  items: items
                      .where((i) => !_hiddenIds.contains(i.id))
                      .toList(),
                  restockOnBuy: _restockOnBuy,
                  onHide: _hide,
                  onUnhide: _unhide,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddItemBar extends StatelessWidget {
  const _AddItemBar({required this.controller, required this.onAdd});

  final TextEditingController controller;
  final Future<void> Function() onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: AppStrings.addToShop,
                prefixIcon: const Icon(Icons.add_shopping_cart_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onSubmitted: (_) => onAdd(),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              minimumSize: const Size(52, 52),
              padding: EdgeInsets.zero,
            ),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _RestockToggle extends StatelessWidget {
  const _RestockToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: const Icon(Icons.autorenew),
        title: const Text(AppStrings.restockOnBuy),
        subtitle: const Text(AppStrings.restockOnBuyHint),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _ShoppingList extends ConsumerWidget {
  const _ShoppingList({
    required this.items,
    required this.restockOnBuy,
    required this.onHide,
    required this.onUnhide,
  });

  final List<ShoppingListItem> items;
  final bool restockOnBuy;
  final void Function(String id) onHide;
  final void Function(String id) onUnhide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _SectionLabel(
          label: AppStrings.shopToBuy,
          count: items.length,
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const _EmptyRow(text: AppStrings.emptyShopHint)
        else
          ...items.map(
            (item) => _ShopItemTile(
              item: item,
              restockOnBuy: restockOnBuy,
              onHide: onHide,
              onUnhide: onUnhide,
            ),
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
      ),
    );
  }
}

class _ShopItemTile extends ConsumerWidget {
  const _ShopItemTile({
    required this.item,
    required this.restockOnBuy,
    required this.onHide,
    required this.onUnhide,
  });

  final ShoppingListItem item;
  final bool restockOnBuy;
  final void Function(String id) onHide;
  final void Function(String id) onUnhide;

  ({IconData icon, String label}) get _source {
    return switch (item.source) {
      'low_stock' => (icon: Icons.inventory_2_outlined, label: AppStrings.sourceLowStock),
      'recipe' => (icon: Icons.restaurant_outlined, label: AppStrings.sourceMealPlan),
      _ => (icon: Icons.edit_outlined, label: AppStrings.sourceManual),
    };
  }

  Future<void> _delete(WidgetRef ref) async {
    await ref.read(shoppingRepositoryProvider).deleteItem(item.id);
    ref.invalidate(shoppingListProvider);
  }

  Future<void> _buy(BuildContext context, WidgetRef ref) async {
    final pantryId = item.pantryItemId;

    // When restock-on-buy is on and the item is linked to a pantry item, ask
    // how much was actually restocked before updating stock.
    double? manualRestock;
    var pantryHandled = false;
    if (restockOnBuy && pantryId != null) {
      final pantry = await ref.read(pantryRepositoryProvider).fetchItem(pantryId);
      if (pantry != null && context.mounted) {
        final result = await showRestockAmountSheet(
          context: context,
          itemName: pantry.name,
          unit: pantry.unit,
          suggestedAmount: item.quantity,
        );
        if (result == null) return; // dismissed — leave item on the list
        pantryHandled = true;
        if (result.restock && result.amount > 0) {
          manualRestock = result.amount;
        }
      }
    }

    // Optimistically remove the row so it feels instant.
    onHide(item.id);

    try {
      if (manualRestock != null && pantryId != null) {
        await ref.read(pantryRepositoryProvider).applyStockEvent(
              itemId: pantryId,
              delta: manualRestock,
              reason: 'restocked',
              note: AppStrings.restockedFromShop,
            );
      }
      await ref.read(shoppingRepositoryProvider).completeItem(
            item.id,
            // Pantry stock already handled above when the modal was used.
            restock: pantryHandled ? false : restockOnBuy,
            pantryItemId: pantryId,
          );
      if (pantryId != null) ref.invalidate(pantryItemProvider(pantryId));
      // Sync the rest in the background — the row is already gone.
      ref.invalidate(shoppingListProvider);
      ref.invalidate(lowStockItemsProvider);
      unawaited(refreshPantryList(ref));
    } catch (_) {
      onUnhide(item.id); // put it back so the user can retry
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.errorGeneric)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final source = _source;
    final quantity = (item.quantity != null && item.unit != null)
        ? Formatters.quantity(item.quantity!, item.unit!)
        : null;

    final selection = ref.watch(multiSelectProvider(MultiSelectKeys.shopping));
    final selectionNotifier =
        ref.read(multiSelectProvider(MultiSelectKeys.shopping).notifier);
    final selecting = selection.active;
    final selected = selection.contains(item.id);

    final card = Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: selected ? theme.colorScheme.primaryContainer : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: selecting
            ? () => selectionNotifier.toggle(item.id)
            : () => _buy(context, ref),
        onLongPress:
            selecting ? null : () => selectionNotifier.enter(item.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Checkbox(
                value: selecting ? selected : false,
                onChanged: selecting
                    ? (_) => selectionNotifier.toggle(item.id)
                    : (_) => _buy(context, ref),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (quantity != null) ...[
                          Text(
                            quantity,
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(width: 8),
                          Text('·', style: theme.textTheme.bodySmall),
                          const SizedBox(width: 8),
                        ],
                        Icon(source.icon,
                            size: 13, color: theme.colorScheme.outline),
                        const SizedBox(width: 4),
                        Text(
                          source.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!selecting)
                IconButton(
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                  tooltip: AppStrings.removeItem,
                  onPressed: () => _delete(ref),
                ),
            ],
          ),
        ),
      ),
    );

    // Swipe-to-delete only makes sense outside selection mode.
    if (selecting) return card;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child:
            Icon(Icons.delete_outline, color: theme.colorScheme.onErrorContainer),
      ),
      onDismissed: (_) => _delete(ref),
      child: card,
    );
  }
}
