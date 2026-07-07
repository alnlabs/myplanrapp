import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../assets/data/asset_repository.dart';
import '../../assets/presentation/asset_form_screen.dart';
import '../../assets/presentation/assets_list_tab.dart';
import '../../pantry/data/pantry_repository.dart';
import 'pantry_list_tab.dart';

enum InventorySegment { food, assets }

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  InventorySegment _segment = InventorySegment.food;
  String _query = '';

  Future<void> _onAdd() async {
    if (_segment == InventorySegment.food) {
      await context.push('/pantry/add');
      ref.invalidate(pantryItemsProvider);
      ref.invalidate(lowStockItemsProvider);
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AssetFormScreen()),
      );
      ref.invalidate(homeAssetsProvider);
      ref.invalidate(warrantyExpiringAssetsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.inventoryTitle),
        actions: [
          IconButton(
            onPressed: _onAdd,
            icon: const Icon(Icons.add),
            tooltip: _segment == InventorySegment.food
                ? AppStrings.addItem
                : AppStrings.addAsset,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<InventorySegment>(
              segments: const [
                ButtonSegment(
                  value: InventorySegment.food,
                  label: Text(AppStrings.segmentFood),
                  icon: Icon(Icons.kitchen_outlined),
                ),
                ButtonSegment(
                  value: InventorySegment.assets,
                  label: Text(AppStrings.segmentAssets),
                  icon: Icon(Icons.inventory_2_outlined),
                ),
              ],
              selected: {_segment},
              onSelectionChanged: (value) {
                setState(() => _segment = value.first);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: AppStrings.search,
              ),
              onChanged: (value) =>
                  setState(() => _query = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (_segment == InventorySegment.food) {
                  ref.invalidate(pantryItemsProvider);
                  await ref.read(pantryItemsProvider.future);
                } else {
                  ref.invalidate(homeAssetsProvider);
                  await ref.read(homeAssetsProvider.future);
                }
              },
              child: _segment == InventorySegment.food
                  ? PantryListTab(query: _query)
                  : AssetsListTab(query: _query),
            ),
          ),
        ],
      ),
    );
  }
}
