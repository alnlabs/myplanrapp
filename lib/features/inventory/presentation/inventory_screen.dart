import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/asset_constants.dart';
import '../../../shared/constants/pantry_constants.dart';
import '../../../shared/providers/list_display_mode_provider.dart';
import '../../../shared/providers/multi_select_provider.dart';
import '../../../shared/widgets/feature_screen_app_bar.dart';
import '../../../shared/widgets/filter_menu_button.dart';
import '../../../shared/widgets/list_display_mode_toggle.dart';
import '../../../shared/widgets/blocking_progress.dart';
import '../../../shared/widgets/selection_app_bar.dart';
import '../../assets/data/asset_repository.dart';
import '../../assets/presentation/asset_form_screen.dart';
import '../../assets/presentation/assets_list_tab.dart';
import '../../home/presentation/app_drawer.dart';
import '../../pantry/data/pantry_items_list_provider.dart';
import '../../pantry/data/pantry_repository.dart';
import 'inventory_all_tab.dart';
import 'pantry_list_tab.dart';

enum InventorySegment { all, food, assets }

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
  String? _pantryCategory; // null = all categories
  bool _searching = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _segment = widget.initialSegment;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSearch() => setState(() => _searching = true);

  void _closeSearch() => setState(() {
        _searching = false;
        _query = '';
        _searchController.clear();
      });

  Future<void> _onAdd() async {
    if (_segment == InventorySegment.assets) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AssetFormScreen()),
      );
      ref.invalidate(homeAssetsProvider);
      ref.invalidate(warrantyExpiringAssetsProvider);
    } else {
      await context.push('/pantry/add');
      await refreshPantryList(ref);
      ref.invalidate(lowStockItemsProvider);
    }
  }

  Future<void> _deleteSelected(String key) async {
    final ids = ref.read(multiSelectProvider(key)).ids.toList();
    if (ids.isEmpty) return;
    final confirmed = await confirmBulkDelete(context, ids.length);
    if (!confirmed || !mounted) return;

    try {
      if (key == MultiSelectKeys.pantry) {
        final repo = ref.read(pantryRepositoryProvider);
        await runWithBlockingProgress(context, () => repo.deleteItems(ids));
        ref.read(multiSelectProvider(key).notifier).clear();
        await refreshPantryList(ref);
        ref.invalidate(lowStockItemsProvider);
      } else {
        final repo = ref.read(assetRepositoryProvider);
        await runWithBlockingProgress(context, () => repo.deleteAssets(ids));
        ref.read(multiSelectProvider(key).notifier).clear();
        ref.invalidate(homeAssetsProvider);
        ref.invalidate(warrantyExpiringAssetsProvider);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.itemsDeleted(ids.length))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.errorGeneric)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFood = _segment == InventorySegment.food;
    final isAssets = _segment == InventorySegment.assets;
    final isAll = _segment == InventorySegment.all;

    final activeKey = isFood
        ? MultiSelectKeys.pantry
        : isAssets
            ? MultiSelectKeys.assets
            : null;
    final selection =
        activeKey != null ? ref.watch(multiSelectProvider(activeKey)) : null;

    List<String> visibleIds = const [];
    if (isFood) {
      visibleIds = filterPantryItems(
        ref.watch(pantryItemsListProvider).items,
        query: _query,
        category: _pantryCategory,
      ).map((e) => e.id).toList();
    } else if (isAssets) {
      visibleIds = filterAssets(
        ref.watch(homeAssetsProvider).valueOrNull ?? const [],
        query: _query,
        category: _pantryCategory,
      ).map((e) => e.id).toList();
    }

    return Scaffold(
      appBar: (selection?.active ?? false)
          ? SelectionAppBar(
              selectedCount: selection!.count,
              totalCount: visibleIds.length,
              onClose: () =>
                  ref.read(multiSelectProvider(activeKey!).notifier).clear(),
              onSelectAll: () {
                final notifier =
                    ref.read(multiSelectProvider(activeKey!).notifier);
                if (selection.count >= visibleIds.length) {
                  notifier.selectAll(const []);
                } else {
                  notifier.selectAll(visibleIds);
                }
              },
              onDelete: () => _deleteSelected(activeKey!),
            )
          : _searching
          ? _buildSearchAppBar(context)
          : FeatureScreenAppBar.forShellRoute(
              context,
              title: AppStrings.inventoryTitle,
              subtitle: AppStrings.inventorySubtitle,
              leading: const DrawerMenuButton(),
              actions: [
                IconButton(
                  tooltip: AppStrings.search,
                  icon: const Icon(Icons.search),
                  onPressed: _openSearch,
                ),
                FilterMenuButton<InventorySegment>(
                  value: _segment,
                  onSelected: (value) => setState(() {
                    _segment = value;
                    _pantryCategory = null;
                  }),
                  options: const [
                    FilterMenuOption(
                      value: InventorySegment.all,
                      label: AppStrings.segmentAll,
                      icon: Icons.apps_outlined,
                    ),
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
        label: Text(isAssets ? AppStrings.addAsset : AppStrings.addItem),
      ),
      body: Column(
        children: [
          const SizedBox(height: 4),
          if (!isAll)
            _CategoryChipsBar(
              options: _categoryOptions(isFood),
              selected: _pantryCategory,
              onSelected: (value) =>
                  setState(() => _pantryCategory = value),
            ),
          if (!isAll) _SummaryLine(isFood: isFood),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await refreshPantryList(ref);
                ref.invalidate(homeAssetsProvider);
                await ref.read(homeAssetsProvider.future);
              },
              child: isAll
                  ? InventoryAllTab(query: _query)
                  : isFood
                      ? PantryListTab(
                          query: _query, category: _pantryCategory)
                      : AssetsListTab(
                          query: _query, category: _pantryCategory),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildSearchAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: AppStrings.close,
        onPressed: _closeSearch,
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(
          hintText: AppStrings.search,
          border: InputBorder.none,
        ),
        onChanged: (value) => setState(() => _query = value.toLowerCase()),
      ),
      actions: [
        if (_query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => setState(() {
              _query = '';
              _searchController.clear();
            }),
          ),
      ],
    );
  }

  List<({String? value, String label})> _categoryOptions(bool isFood) {
    return [
      const (value: null, label: AppStrings.allCategories),
      if (isFood)
        for (final c in PantryCategories.values) (value: c, label: c)
      else
        for (final c in AssetCategories.all) (value: c.value, label: c.label),
    ];
  }
}

/// Horizontally scrollable category chips shown below the search bar.
class _CategoryChipsBar extends StatelessWidget {
  const _CategoryChipsBar({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<({String? value, String label})> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option.value == selected;
          return ChoiceChip(
            label: Text(option.label),
            selected: isSelected,
            onSelected: (_) => onSelected(option.value),
          );
        },
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
