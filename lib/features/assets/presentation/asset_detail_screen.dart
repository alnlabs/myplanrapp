import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/asset_constants.dart';
import '../../../shared/providers/record_permissions.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../../../shared/widgets/warranty_chip.dart';
import '../data/asset_repository.dart';
import 'asset_form_screen.dart';
import 'asset_attachments_section.dart';
import 'service_record_form_screen.dart';

class AssetDetailScreen extends ConsumerWidget {
  const AssetDetailScreen({super.key, required this.assetId});

  final String assetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetAsync = ref.watch(homeAssetProvider(assetId));
    final recordsAsync = ref.watch(assetServiceRecordsProvider(assetId));
    final currentUserId = ref.watch(currentUserIdProvider);
    final isOwner = ref.watch(isHouseholdOwnerProvider);

    return Scaffold(
      appBar: AppBar(
        title: assetAsync.when(
          data: (asset) => Text(asset?.name ?? AppStrings.assetsTitle),
          loading: () => const Text(AppStrings.assetsTitle),
          error: (_, __) => const Text(AppStrings.assetsTitle),
        ),
        actions: [
          assetAsync.whenOrNull(
            data: (asset) {
              if (asset == null) return null;
              final canEdit = canManageRecord(
                createdBy: asset.createdBy,
                currentUserId: currentUserId,
                isOwner: isOwner,
              );
              if (!canEdit) return null;
              return IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AssetFormScreen(assetId: asset.id),
                    ),
                  );
                  ref.invalidate(homeAssetProvider(assetId));
                  ref.invalidate(homeAssetsProvider);
                },
              );
            },
          ) ??
              const SizedBox.shrink(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final asset = assetAsync.valueOrNull;
          if (asset == null) return;
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ServiceRecordFormScreen(
                assetId: asset.id,
                householdId: asset.householdId,
              ),
            ),
          );
          ref.invalidate(assetServiceRecordsProvider(assetId));
        },
        icon: const Icon(Icons.build_outlined),
        label: const Text(AppStrings.logRepair),
      ),
      body: AsyncScreenBody(
        value: assetAsync,
        onRetry: () => ref.invalidate(homeAssetProvider(assetId)),
        builder: (asset) {
          if (asset == null) {
            return const Center(child: Text(AppStrings.errorGeneric));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Text(
                asset.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(AssetCategories.labelFor(asset.category))),
                  Chip(label: Text(AssetStatuses.labelFor(asset.status))),
                  WarrantyChip(status: asset.warrantyStatus),
                ],
              ),
              if (asset.description != null) ...[
                const SizedBox(height: 12),
                Text(asset.description!),
              ],
              const SizedBox(height: 16),
              if (asset.location != null) _Row(AppStrings.assetLocation, asset.location!),
              if (asset.vendorName != null) _Row(AppStrings.whereBought, asset.vendorName!),
              if (asset.purchaseDate != null)
                _Row(AppStrings.purchaseDate, Formatters.date(asset.purchaseDate!)),
              if (asset.purchaseAmount != null)
                _Row(AppStrings.purchaseAmount, Formatters.currency(asset.purchaseAmount!)),
              if (asset.warrantyEnd != null)
                _Row(AppStrings.warrantyEnd, Formatters.date(asset.warrantyEnd!)),
              if (asset.warrantyProvider != null)
                _Row(AppStrings.warrantyProvider, asset.warrantyProvider!),
              const SizedBox(height: 24),
              AssetAttachmentsSection(
                assetId: asset.id,
                householdId: asset.householdId,
              ),
              const SizedBox(height: 24),
              Text(AppStrings.repairHistory, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              recordsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text(AppStrings.errorGeneric),
                data: (records) {
                  if (records.isEmpty) {
                    return const Text(AppStrings.noRepairHistory);
                  }
                  return Column(
                    children: records.map((r) {
                      final title = switch (r.serviceType) {
                        ServiceTypes.shopRepair => r.shopName ?? 'Shop repair',
                        ServiceTypes.thirdParty =>
                          r.platformName ?? 'Third-party service',
                        _ => 'DIY',
                      };
                      final parts = <String>[Formatters.date(r.serviceDate)];
                      if (r.cost != null) parts.add(Formatters.currency(r.cost!));
                      if (r.notes != null && r.notes!.isNotEmpty) {
                        parts.add(r.notes!);
                      }
                      return Card(
                        child: ListTile(
                          title: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            parts.join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
