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
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final asset = filtered[index];
            return Card(
              child: ListTile(
                leading: Icon(_iconFor(asset.category)),
                title: Text(asset.name),
                subtitle: Text(
                  [
                    AssetCategories.labelFor(asset.category),
                    if (asset.location != null) asset.location!,
                  ].join(' · '),
                ),
                trailing: WarrantyChip(status: asset.warrantyStatus),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AssetDetailScreen(assetId: asset.id),
                  ),
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
