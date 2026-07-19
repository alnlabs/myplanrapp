import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/models/home_asset.dart';
import '../../../shared/models/pantry_item.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/paginated_list_footer.dart';
import '../../assets/data/asset_repository.dart';
import '../../assets/presentation/asset_detail_screen.dart';
import '../../assets/presentation/assets_list_tab.dart';
import '../../pantry/data/pantry_items_list_provider.dart';
import '../../pantry/presentation/pantry_item_detail_screen.dart';
import 'pantry_list_tab.dart';

/// Combined "All" view: Food (pantry) and Assets sections in one scroll.
/// Pantry paginates as you scroll; assets load as a full set below.
class InventoryAllTab extends ConsumerWidget {
  const InventoryAllTab({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pantryState = ref.watch(pantryItemsListProvider);
    final assetsAsync = ref.watch(homeAssetsProvider);

    if (pantryState.isInitialLoading || assetsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (pantryState.hasError) {
      return ErrorView(
        error: pantryState.error!,
        message: ApiErrorFormatter.format(pantryState.error!),
        onRetry: () => ref.read(pantryItemsListProvider.notifier).refresh(),
      );
    }

    final pantry = _filterPantry(pantryState.items);
    final assets = _filterAssets(assetsAsync.valueOrNull ?? const []);

    if (pantry.isEmpty && assets.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          EmptyState(
            icon: Icons.inventory_2_outlined,
            title: AppStrings.emptyPantry,
            subtitle: AppStrings.emptyPantryHint,
          ),
        ],
      );
    }

    return PaginatedScrollListener(
      onLoadMore: () => ref.read(pantryItemsListProvider.notifier).loadMore(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (pantry.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.kitchen_outlined,
              label: AppStrings.segmentFood,
              count: pantry.length,
            ),
            for (final item in pantry) ...[
              PantryListTile(
                item: item,
                onTap: () => _openPantry(context, item),
              ),
              const SizedBox(height: 8),
            ],
            PaginatedListFooter(
              state: pantryState,
              idleHeight: 0,
              onRetryLoadMore: () =>
                  ref.read(pantryItemsListProvider.notifier).loadMore(),
            ),
          ],
          if (assets.isNotEmpty) ...[
            const SizedBox(height: 8),
            _SectionHeader(
              icon: Icons.inventory_2_outlined,
              label: AppStrings.segmentAssets,
              count: assets.length,
            ),
            for (final asset in assets) ...[
              AssetListTile(
                asset: asset,
                onTap: () => _openAsset(context, asset),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }

  List<PantryItem> _filterPantry(List<PantryItem> items) {
    if (query.isEmpty) return items;
    return items
        .where((i) =>
            i.name.toLowerCase().contains(query) ||
            (i.brandLabel?.toLowerCase().contains(query) ?? false) ||
            (i.category?.toLowerCase().contains(query) ?? false))
        .toList();
  }

  List<HomeAsset> _filterAssets(List<HomeAsset> assets) {
    if (query.isEmpty) return assets;
    return assets
        .where((a) =>
            a.name.toLowerCase().contains(query) ||
            (a.location?.toLowerCase().contains(query) ?? false))
        .toList();
  }

  void _openPantry(BuildContext context, PantryItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PantryItemDetailScreen(item: item)),
    );
  }

  void _openAsset(BuildContext context, HomeAsset asset) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
          builder: (_) => AssetDetailScreen(assetId: asset.id)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 6),
          Text(
            '($count)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
