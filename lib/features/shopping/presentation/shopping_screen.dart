import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/models/shopping_list_item.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../../auth/data/auth_repository.dart';
import '../../pantry/data/pantry_repository.dart';
import '../data/shopping_repository.dart';

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

  Future<void> _addManual() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final profile = await ref.read(userProfileProvider.future);
    final householdId = profile?.activeHouseholdId;
    if (householdId == null) return;
    await ref.read(shoppingRepositoryProvider).addItem(
          householdId: householdId,
          name: name,
        );
    _nameController.clear();
    ref.invalidate(shoppingListProvider);
  }

  Future<void> _clearBought() async {
    final profile = await ref.read(userProfileProvider.future);
    final householdId = profile?.activeHouseholdId;
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
          IconButton(
            onPressed: () async {
              final profile = await ref.read(userProfileProvider.future);
              final householdId = profile?.activeHouseholdId;
              if (householdId == null) return;
              await ref
                  .read(shoppingRepositoryProvider)
                  .generateFromLowStock(householdId);
              ref.invalidate(shoppingListProvider);
            },
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: AppStrings.generateFromLowStock,
          ),
          IconButton(
            onPressed: _clearBought,
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: AppStrings.clearChecked,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.restockOnBuy),
              value: _restockOnBuy,
              onChanged: (v) => setState(() => _restockOnBuy = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: AppStrings.addToShop),
                    onSubmitted: (_) => _addManual(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _addManual,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
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

class _ShoppingList extends ConsumerWidget {
  const _ShoppingList({
    required this.items,
    required this.restockOnBuy,
  });

  final List<ShoppingListItem> items;
  final bool restockOnBuy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final subtitle = [
          if (item.quantity != null && item.unit != null)
            Formatters.quantity(item.quantity!, item.unit!),
          switch (item.source) {
            'low_stock' => AppStrings.sourceLowStock,
            'recipe' => AppStrings.sourceRecipe,
            _ => AppStrings.sourceManual,
          },
        ].join(' · ');

        return Card(
          child: CheckboxListTile(
            value: item.isChecked,
            onChanged: (checked) async {
              if (checked == true && !item.isChecked) {
                await ref.read(shoppingRepositoryProvider).completeItem(
                      item.id,
                      restock: restockOnBuy,
                    );
                ref.invalidate(shoppingListProvider);
                ref.invalidate(pantryItemsProvider);
                ref.invalidate(lowStockItemsProvider);
              } else if (checked == false) {
                await ref
                    .read(shoppingRepositoryProvider)
                    .toggleChecked(item.id, false);
                ref.invalidate(shoppingListProvider);
              }
            },
            title: Text(
              item.name,
              style: item.isChecked
                  ? const TextStyle(decoration: TextDecoration.lineThrough)
                  : null,
            ),
            subtitle: Text(subtitle),
          ),
        );
      },
    );
  }
}
