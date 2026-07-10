import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/asset_constants.dart';
import '../../../shared/models/home_asset.dart';
import '../../../shared/providers/list_display_mode_provider.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../../../shared/widgets/compact_grid_card.dart';
import '../../../shared/widgets/list_grid_layout.dart';
import '../data/asset_repository.dart';
import 'asset_detail_screen.dart';

class AssetsListTab extends ConsumerWidget {
  const AssetsListTab({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(homeAssetsProvider);
    final viewMode =
        ref.watch(listDisplayModeProvider(ListDisplayModeKeys.assets));

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

        if (viewMode == ListDisplayMode.list) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final asset = filtered[index];
              return _AssetListTile(
                asset: asset,
                icon: _iconFor(asset.category),
                onTap: () => _openAsset(context, asset),
              );
            },
          );
        }

        return GridView.builder(
          padding: ListGridLayout.padding,
          gridDelegate: ListGridLayout.tabGridDelegate,
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final asset = filtered[index];
            return _AssetGridCard(
              asset: asset,
              icon: _iconFor(asset.category),
              onTap: () => _openAsset(context, asset),
            );
          },
        );
      },
    );
  }

  void _openAsset(BuildContext context, HomeAsset asset) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AssetDetailScreen(assetId: asset.id),
      ),
    );
  }

  List<HomeAsset> _filter(List<HomeAsset> assets) {
    if (query.isEmpty) return assets;
    return assets
        .where(
          (a) =>
              a.name.toLowerCase().contains(query) ||
              (a.location?.toLowerCase().contains(query) ?? false) ||
              AssetCategories.labelFor(a.category)
                  .toLowerCase()
                  .contains(query),
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

Color _warrantyColor(WarrantyStatus status) => switch (status) {
      WarrantyStatus.valid => Colors.green.shade700,
      WarrantyStatus.expiring => Colors.amber.shade800,
      WarrantyStatus.expired => Colors.red.shade700,
      WarrantyStatus.none => Colors.grey,
    };

class _AssetListTile extends StatelessWidget {
  const _AssetListTile({
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
    final subtitleParts = [
      AssetCategories.labelFor(asset.category),
      if (asset.location != null) asset.location!,
      if (asset.warrantyStatus != WarrantyStatus.none)
        switch (asset.warrantyStatus) {
          WarrantyStatus.valid => AppStrings.warrantyValid,
          WarrantyStatus.expiring => AppStrings.warrantyExpiring,
          WarrantyStatus.expired => AppStrings.warrantyExpired,
          WarrantyStatus.none => '',
        },
    ];

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Icon(
                  icon,
                  color: theme.colorScheme.onSecondaryContainer,
                  size: 20,
                ),
              ),
              if (asset.warrantyStatus != WarrantyStatus.none)
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 10,
                    height: 10,
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
          title: Text(
            asset.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitleParts.join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right, size: 20),
        ),
      ),
    );
  }
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

    return CompactGridCard(
      onTap: onTap,
      leading: CompactGridIcon(
        icon: icon,
        color: theme.colorScheme.onSecondaryContainer,
        backgroundColor: theme.colorScheme.secondaryContainer,
        badgeColor: asset.warrantyStatus != WarrantyStatus.none
            ? _warrantyColor(asset.warrantyStatus)
            : null,
      ),
      title: asset.name,
      subtitle: [
        AssetCategories.labelFor(asset.category),
        if (asset.location != null) asset.location!,
      ].join(' · '),
    );
  }
}
