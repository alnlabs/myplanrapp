import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/providers/list_display_mode_provider.dart';
import '../../../shared/widgets/feature_screen_app_bar.dart';
import '../../../shared/widgets/filter_menu_button.dart';
import '../../../shared/widgets/list_display_mode_toggle.dart';
import '../../assets/data/asset_repository.dart';
import '../../assets/presentation/asset_form_screen.dart';
import '../../assets/presentation/assets_list_tab.dart';
import '../../pantry/data/pantry_items_list_provider.dart';
import '../../pantry/data/pantry_repository.dart';
import 'pantry_list_tab.dart';

enum InventorySegment { food, assets }

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({
    super.key,
    this.initialSegment = InventorySegment.food,
  });

  final InventorySegment initialSegment;

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  late InventorySegment _segment;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _segment = widget.initialSegment;
  }

  Future<void> _onAdd() async {
    if (_segment == InventorySegment.food) {
      await context.push('/pantry/add');
      await refreshPantryList(ref);
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
    final isFood = _segment == InventorySegment.food;

    return Scaffold(
      appBar: FeatureScreenAppBar.forShellRoute(
        context,
        title: AppStrings.inventoryTitle,
        subtitle: AppStrings.inventorySubtitle,
        actions: [
          FilterMenuButton<InventorySegment>(
            value: _segment,
            onSelected: (value) => setState(() => _segment = value),
            options: const [
              FilterMenuOption(
                value: InventorySegment.food,
                label: AppStrings.segmentFood,
                icon: Icons.kitchen_outlined,
              ),
              FilterMenuOption(
                value: InventorySegment.assets,
                label: AppStrings.segmentAssets,
                icon: Icons.inventory_2_outlined,
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAdd,
        icon: const Icon(Icons.add),
        label: Text(isFood ? AppStrings.addItem : AppStrings.addAsset),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchBar(
              hintText: AppStrings.search,
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(
                Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.5),
              ),
              onChanged: (value) =>
                  setState(() => _query = value.toLowerCase()),
            ),
          ),
          _SummaryLine(isFood: isFood),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (isFood) {
                  await refreshPantryList(ref);
                } else {
                  ref.invalidate(homeAssetsProvider);
                  await ref.read(homeAssetsProvider.future);
                }
              },
              child: isFood
                  ? PantryListTab(query: _query)
                  : AssetsListTab(query: _query),
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact one-line summary shown above the list.
class _SummaryLine extends ConsumerWidget {
  const _SummaryLine({required this.isFood});

  final bool isFood;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final screenKey = isFood
        ? ListDisplayModeKeys.pantry
        : ListDisplayModeKeys.assets;

    final int count;
    final int alert;
    final String countLabel;
    final String alertLabel;
    final IconData alertIcon;

    if (isFood) {
      final listState = ref.watch(pantryItemsListProvider);
      if (!listState.hasMore &&
          !listState.isLoading &&
          listState.error == null) {
        count = listState.items.length;
      } else {
        count = ref.watch(pantryItemCountProvider).valueOrNull ??
            listState.items.length;
      }
      alert = ref.watch(lowStockItemsProvider.select((a) => a.valueOrNull?.length ?? 0));
      countLabel = count == 1 ? '1 item' : '$count items';
      alertLabel = '$alert ${AppStrings.lowStock.toLowerCase()}';
      alertIcon = Icons.warning_amber_rounded;
    } else {
      final assets = ref.watch(homeAssetsProvider).valueOrNull ?? [];
      final expiring =
          ref.watch(warrantyExpiringAssetsProvider).valueOrNull ?? [];
      count = assets.length;
      alert = expiring.length;
      countLabel = AppStrings.homeItemCount(count);
      alertLabel = '$alert ${AppStrings.warrantyExpiring.toLowerCase()}';
      alertIcon = Icons.verified_outlined;
    }

    final alertColor =
        alert > 0 ? Colors.orange.shade800 : theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 12, 6),
      child: Row(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 15,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            countLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (alert > 0) ...[
            const SizedBox(width: 12),
            Icon(alertIcon, size: 15, color: alertColor),
            const SizedBox(width: 6),
            Text(
              alertLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: alertColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const Spacer(),
          ListDisplayModeToggle(screenKey: screenKey, compact: true),
        ],
      ),
    );
  }
}
