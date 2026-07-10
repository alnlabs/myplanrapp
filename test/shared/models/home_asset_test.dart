import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/constants/asset_constants.dart';
import 'package:myplanr/shared/models/home_asset.dart';

void main() {
  group('HomeAsset', () {
    test('warrantyStatus delegates to warrantyStatusFor', () {
      final asset = HomeAsset(
        id: 'a1',
        householdId: 'hh',
        name: 'TV',
        category: AssetCategories.electronics,
        itemKind: AssetKinds.permanent,
        status: AssetStatuses.active,
        warrantyEnd: DateTime.now().add(const Duration(days: 10)),
      );
      expect(asset.warrantyStatus, WarrantyStatus.expiring);
    });

    test('fromJson parses dates and amounts', () {
      final asset = HomeAsset.fromJson({
        'id': 'a1',
        'household_id': 'hh',
        'name': 'Fridge',
        'category': 'appliance',
        'item_kind': 'permanent',
        'status': 'active',
        'purchase_date': '2024-01-15',
        'purchase_amount': 25000,
        'warranty_end': '2027-01-15',
      });
      expect(asset.purchaseAmount, 25000);
      expect(asset.purchaseDate, DateTime(2024, 1, 15));
      expect(asset.warrantyEnd, DateTime(2027, 1, 15));
    });

    test('toJson formats date fields as ISO date', () {
      final asset = HomeAsset(
        id: 'a1',
        householdId: 'hh',
        name: 'Laptop',
        category: AssetCategories.electronics,
        itemKind: AssetKinds.permanent,
        status: AssetStatuses.active,
        purchaseDate: DateTime(2025, 5, 1),
      );
      final json = asset.toJson('hh', 'u1');
      expect(json['purchase_date'], '2025-05-01');
      expect(json['household_id'], 'hh');
    });
  });

  group('AssetServiceRecord', () {
    test('fromJson and toInsertJson', () {
      final record = AssetServiceRecord.fromJson({
        'id': 'r1',
        'asset_id': 'a1',
        'household_id': 'hh',
        'service_type': ServiceTypes.diy,
        'service_date': '2026-03-01',
        'cost': 500,
      });
      expect(record.serviceType, ServiceTypes.diy);
      final json = record.toInsertJson('a1', 'hh', 'u1');
      expect(json['service_date'], '2026-03-01');
      expect(json['cost'], 500);
    });
  });
}
