import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/asset_constants.dart';
import '../../../shared/models/home_asset.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../../../shared/widgets/warranty_chip.dart';
import '../data/asset_repository.dart';
import 'asset_detail_screen.dart';

class AssetsListTab extends ConsumerWidget {
  const AssetsListTab({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(homeAssetsProvider);

    return AsyncScreenBody(
      value: assetsAsync,
      onRetry: () => ref.invalidate(homeAssetsProvider),
      isEmpty: (items) => _filter(items).isEmpty,
      emptyTitle: AppStrings.emptyAssets,
      emptySubtitle: AppStrings.emptyAssetsHint,
      builder: (assets) {
        final filtered = _filter(assets);
        if (filtered.isEmpty) {
          return ListView(
            children: const [
              SizedBox(height: 64),
              Center(child: Text(AppStrings.emptyAssets)),
            ],
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.35,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final asset = filtered[index];
            return _AssetGridCard(
              asset: asset,
              icon: _iconFor(asset.category),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AssetDetailScreen(assetId: asset.id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<HomeAsset> _filter(List<HomeAsset> assets) {
    if (query.isEmpty) return assets;
    return assets
        .where(
          (a) =>
              a.name.toLowerCase().contains(query) ||
              (a.location?.toLowerCase().contains(query) ?? false) ||
              AssetCategories.labelFor(a.category).toLowerCase().contains(query),
        )
        .toList();
  }

  IconData _iconFor(String category) => switch (category) {
        AssetCategories.electronics => Icons.devices_outlined,
        AssetCategories.appliance => Icons.kitchen_outlined,
        AssetCategories.furniture => Icons.chair_outlined,
        AssetCategories.cable => Icons.cable_outlined,
        _ => Icons.inventory_2_outlined,
      };
}

class _AssetGridCard extends StatelessWidget {
  const _AssetGridCard({
    required this.asset,
    required this.icon,
    required this.onTap,
  });

  final HomeAsset asset;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    child: Icon(
                      icon,
                      color: theme.colorScheme.onSecondaryContainer,
                      size: 18,
                    ),
                  ),
                  WarrantyChip(status: asset.warrantyStatus),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      AssetCategories.labelFor(asset.category),
                      if (asset.location != null) asset.location!,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
