import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/constants/asset_constants.dart';

void main() {
  group('warrantyStatusFor', () {
    test('none when no end date', () {
      expect(warrantyStatusFor(null), WarrantyStatus.none);
    });

    test('expired when end date is past', () {
      final past = DateTime.now().subtract(const Duration(days: 10));
      expect(warrantyStatusFor(past), WarrantyStatus.expired);
    });

    test('expiring within 30 days', () {
      final soon = DateTime.now().add(const Duration(days: 15));
      expect(warrantyStatusFor(soon), WarrantyStatus.expiring);
    });

    test('valid when more than 30 days remain', () {
      final future = DateTime.now().add(const Duration(days: 60));
      expect(warrantyStatusFor(future), WarrantyStatus.valid);
    });
  });

  group('AssetCategories.labelFor', () {
    test('returns label for known category', () {
      expect(AssetCategories.labelFor(AssetCategories.electronics), 'Electronics');
    });

    test('falls back to Other', () {
      expect(AssetCategories.labelFor('unknown'), 'Other');
    });
  });

  group('AssetStatuses.labelFor', () {
    test('returns label for active status', () {
      expect(AssetStatuses.labelFor(AssetStatuses.active), 'Active');
    });
  });
}
