import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/asset_constants.dart';
import '../../../shared/models/home_asset.dart';
import '../../../shared/widgets/async_screen_body.dart';
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
            maxCrossAxisExtent: 118,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 124,
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

  Color _warrantyColor(WarrantyStatus status) => switch (status) {
        WarrantyStatus.valid => Colors.green.shade700,
        WarrantyStatus.expiring => Colors.amber.shade800,
        WarrantyStatus.expired => Colors.red.shade700,
        WarrantyStatus.none => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    child: Icon(
                      icon,
                      color: theme.colorScheme.onSecondaryContainer,
                      size: 22,
                    ),
                  ),
                  if (asset.warrantyStatus != WarrantyStatus.none)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _warrantyColor(asset.warrantyStatus),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                asset.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.1,
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
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
