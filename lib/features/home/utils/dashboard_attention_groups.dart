import '../../../core/strings/app_strings.dart';
import '../../../shared/models/home_asset.dart';
import '../../../shared/models/pantry_item.dart';
import '../../../shared/models/subscription.dart';
import '../../../shared/utils/formatters.dart';

/// One attention row on the home dashboard (low stock, expiry, warranty, bills).
class DashboardAttentionGroupData {
  const DashboardAttentionGroupData({
    required this.kind,
    required this.title,
    required this.previews,
    required this.totalCount,
  });

  final String kind;
  final String title;
  final List<String> previews;
  final int totalCount;
}

/// Builds grouped "needs attention" preview rows for [DashboardScreen].
List<DashboardAttentionGroupData> buildDashboardAttentionGroups({
  required bool showPantry,
  required bool showAssets,
  required bool showSubscriptions,
  required List<PantryItem> lowStock,
  required List<PantryItem> expiring,
  required List<HomeAsset> warranty,
  required List<Subscription> subs,
  DateTime? now,
  int previewLimit = 2,
}) {
  final reference = now ?? DateTime.now();
  final groups = <DashboardAttentionGroupData>[];

  if (showPantry) {
    if (lowStock.isNotEmpty) {
      groups.add(
        DashboardAttentionGroupData(
          kind: 'low_stock',
          title: AppStrings.alertsTitle,
          previews: lowStock.take(previewLimit).map((item) {
            if (item.hasManualAttention) {
              return '${item.name} · ${item.attentionLabel}';
            }
            return item.name;
          }).toList(),
          totalCount: lowStock.length,
        ),
      );
    }

    if (expiring.isNotEmpty) {
      groups.add(
        DashboardAttentionGroupData(
          kind: 'expiring',
          title: AppStrings.expiringSoon,
          previews: expiring.take(previewLimit).map((item) {
            final expiry = item.expiryDate!;
            final days = expiry.difference(reference).inDays;
            final when = switch (days) {
              0 => 'today',
              1 => 'tomorrow',
              _ => 'in $days days',
            };
            return '${item.name} · $when';
          }).toList(),
          totalCount: expiring.length,
        ),
      );
    }
  }

  if (showAssets && warranty.isNotEmpty) {
    groups.add(
      DashboardAttentionGroupData(
        kind: 'warranty',
        title: AppStrings.warrantyExpiringTitle,
        previews: warranty.take(previewLimit).map((asset) {
          final end = asset.warrantyEnd;
          if (end == null) return asset.name;
          return '${asset.name} · ${Formatters.date(end)}';
        }).toList(),
        totalCount: warranty.length,
      ),
    );
  }

  if (showSubscriptions && subs.isNotEmpty) {
    groups.add(
      DashboardAttentionGroupData(
        kind: 'subscriptions',
        title: AppStrings.subscriptionsDueSoon,
        previews: subs.take(previewLimit).map((sub) {
          return '${sub.name} · ${Formatters.date(sub.nextDueDate)}';
        }).toList(),
        totalCount: subs.length,
      ),
    );
  }

  return groups;
}

int dashboardAttentionTotalCount(List<DashboardAttentionGroupData> groups) {
  return groups.fold<int>(0, (sum, group) => sum + group.totalCount);
}
