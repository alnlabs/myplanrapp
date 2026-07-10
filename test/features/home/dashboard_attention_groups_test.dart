import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/home/utils/dashboard_attention_groups.dart';
import 'package:myplanr/shared/constants/pantry_availability.dart';
import 'package:myplanr/shared/models/home_asset.dart';
import 'package:myplanr/shared/models/pantry_item.dart';
import 'package:myplanr/shared/models/subscription.dart';

import '../../helpers/test_fixtures.dart';

void main() {
  final now = DateTime(2025, 6, 15, 12);

  PantryItem pantry({
    required String name,
    double quantity = 1,
    String? availabilityStatus,
    DateTime? expiryDate,
  }) {
    return PantryItem(
      id: 'p-$name',
      householdId: testHouseholdId,
      name: name,
      quantity: quantity,
      unit: 'kg',
      availabilityStatus: availabilityStatus,
      expiryDate: expiryDate,
    );
  }

  group('buildDashboardAttentionGroups', () {
    test('returns empty when all modules hidden', () {
      expect(
        buildDashboardAttentionGroups(
          showPantry: false,
          showAssets: false,
          showSubscriptions: false,
          lowStock: [pantry(name: 'Rice', quantity: 0)],
          expiring: [pantry(name: 'Milk', expiryDate: now)],
          warranty: const [
            HomeAsset(
              id: 'a1',
              householdId: testHouseholdId,
              name: 'TV',
              category: 'electronics',
              itemKind: 'permanent',
              status: 'active',
            ),
          ],
          subs: [testSubscription],
        ),
        isEmpty,
      );
    });

    test('groups low stock with manual attention label', () {
      final groups = buildDashboardAttentionGroups(
        showPantry: true,
        showAssets: false,
        showSubscriptions: false,
        lowStock: [
          pantry(
            name: 'Oil',
            availabilityStatus: PantryAvailability.warning,
          ),
        ],
        expiring: const [],
        warranty: const [],
        subs: const [],
        now: now,
      );

      expect(groups, hasLength(1));
      expect(groups.first.kind, 'low_stock');
      expect(groups.first.title, AppStrings.alertsTitle);
      expect(groups.first.previews.single, contains('Oil'));
      expect(groups.first.previews.single, contains(PantryAvailability.label(
        PantryAvailability.warning,
      )));
    });

    test('formats expiring items relative to now', () {
      final groups = buildDashboardAttentionGroups(
        showPantry: true,
        showAssets: false,
        showSubscriptions: false,
        lowStock: const [],
        expiring: [
          pantry(name: 'Yogurt', expiryDate: now),
          pantry(
            name: 'Bread',
            expiryDate: now.add(const Duration(days: 1)),
          ),
          pantry(
            name: 'Cheese',
            expiryDate: now.add(const Duration(days: 3)),
          ),
        ],
        warranty: const [],
        subs: const [],
        now: now,
        previewLimit: 2,
      );

      expect(groups.single.kind, 'expiring');
      expect(groups.single.totalCount, 3);
      expect(groups.single.previews, hasLength(2));
      expect(groups.single.previews[0], 'Yogurt · today');
      expect(groups.single.previews[1], 'Bread · tomorrow');
    });

    test('includes warranty and subscription groups when enabled', () {
      final groups = buildDashboardAttentionGroups(
        showPantry: false,
        showAssets: true,
        showSubscriptions: true,
        lowStock: const [],
        expiring: const [],
        warranty: [
          HomeAsset(
            id: 'a1',
            householdId: testHouseholdId,
            name: 'Fridge',
            category: 'appliance',
            itemKind: 'permanent',
            status: 'active',
            warrantyEnd: DateTime(2025, 7, 1),
          ),
        ],
        subs: [testSubscription],
        now: now,
      );

      expect(groups, hasLength(2));
      expect(groups[0].kind, 'warranty');
      expect(groups[1].kind, 'subscriptions');
      expect(groups[1].previews.single, contains('Netflix'));
    });
  });

  group('dashboardAttentionTotalCount', () {
    test('sums totalCount across groups', () {
      final total = dashboardAttentionTotalCount([
        const DashboardAttentionGroupData(
          kind: 'low_stock',
          title: 'Low',
          previews: ['A'],
          totalCount: 2,
        ),
        const DashboardAttentionGroupData(
          kind: 'expiring',
          title: 'Exp',
          previews: ['B'],
          totalCount: 3,
        ),
      ]);
      expect(total, 5);
    });
  });
}
