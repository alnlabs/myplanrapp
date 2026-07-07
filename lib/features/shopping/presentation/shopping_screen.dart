import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/models/shopping_list_item.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../../auth/data/auth_repository.dart';
import '../../pantry/data/pantry_repository.dart';
import '../data/shopping_repository.dart';

enum _ShopMenuAction { addLowStock, clearBought }

class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  final _nameController = TextEditingController();
  bool _restockOnBuy = true;

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

  Future<void> _addLowStock() async {
    final householdId = await _householdId();
    if (householdId == null) return;
    await ref.read(shoppingRepositoryProvider).generateFromLowStock(householdId);
    ref.invalidate(shoppingListProvider);
  }

  Future<void> _clearBought() async {
    final householdId = await _householdId();
    if (householdId == null) return;
    await ref.read(shoppingRepositoryProvider).clearChecked(householdId);
    ref.invalidate(shoppingListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(shoppingListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.shopTitle),
        actions: [
          PopupMenuButton<_ShopMenuAction>(
            onSelected: (action) {
              switch (action) {
                case _ShopMenuAction.addLowStock:
                  _addLowStock();
                case _ShopMenuAction.clearBought:
                  _clearBought();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _ShopMenuAction.addLowStock,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.inventory_2_outlined),
                  title: Text(AppStrings.generateFromLowStock),
                ),
              ),
              PopupMenuItem(
                value: _ShopMenuAction.clearBought,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_sweep_outlined),
                  title: Text(AppStrings.clearChecked),
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
                  items: items,
                  restockOnBuy: _restockOnBuy,
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
  });

  final List<ShoppingListItem> items;
  final bool restockOnBuy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toBuy = items.where((i) => !i.isChecked).toList();
    final bought = items.where((i) => i.isChecked).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _SectionLabel(
          label: AppStrings.shopToBuy,
          count: toBuy.length,
        ),
        const SizedBox(height: 8),
        if (toBuy.isEmpty)
          const _EmptyRow(text: AppStrings.emptyShopHint)
        else
          ...toBuy.map(
            (item) => _ShopItemTile(
              item: item,
              restockOnBuy: restockOnBuy,
            ),
          ),
        if (bought.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionLabel(
            label: AppStrings.shopBought,
            count: bought.length,
          ),
          const SizedBox(height: 8),
          ...bought.map(
            (item) => _ShopItemTile(
              item: item,
              restockOnBuy: restockOnBuy,
            ),
          ),
        ],
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
  const _ShopItemTile({required this.item, required this.restockOnBuy});

  final ShoppingListItem item;
  final bool restockOnBuy;

  ({IconData icon, String label}) get _source {
    return switch (item.source) {
      'low_stock' => (icon: Icons.inventory_2_outlined, label: AppStrings.sourceLowStock),
      'recipe' => (icon: Icons.receipt_long_outlined, label: AppStrings.sourceRecipe),
      _ => (icon: Icons.edit_outlined, label: AppStrings.sourceManual),
    };
  }

  Future<void> _delete(WidgetRef ref) async {
    await ref.read(shoppingRepositoryProvider).deleteItem(item.id);
    ref.invalidate(shoppingListProvider);
  }

  Future<void> _toggle(WidgetRef ref, bool checked) async {
    if (checked && !item.isChecked) {
      await ref.read(shoppingRepositoryProvider).completeItem(
            item.id,
            restock: restockOnBuy,
          );
      ref.invalidate(shoppingListProvider);
      ref.invalidate(pantryItemsProvider);
      ref.invalidate(lowStockItemsProvider);
    } else if (!checked) {
      await ref.read(shoppingRepositoryProvider).toggleChecked(item.id, false);
      ref.invalidate(shoppingListProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final source = _source;
    final quantity = (item.quantity != null && item.unit != null)
        ? Formatters.quantity(item.quantity!, item.unit!)
        : null;

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
        child: Icon(Icons.delete_outline, color: theme.colorScheme.onErrorContainer),
      ),
      onDismissed: (_) => _delete(ref),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _toggle(ref, !item.isChecked),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Checkbox(
                  value: item.isChecked,
                  onChanged: (v) => _toggle(ref, v ?? false),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          decoration: item.isChecked
                              ? TextDecoration.lineThrough
                              : null,
                          color: item.isChecked ? theme.colorScheme.outline : null,
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
                          Icon(source.icon, size: 13, color: theme.colorScheme.outline),
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
      ),
    );
  }
}
