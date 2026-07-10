import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/shared/constants/pantry_availability.dart';
import 'package:myplanr/shared/models/pantry_item.dart';

PantryItem _item({
  double quantity = 1,
  String unit = 'kg',
  double? lowStockThreshold,
  String? lowStockUnit,
  String? availabilityStatus,
  DateTime? expiryDate,
}) {
  return PantryItem(
    id: 'p1',
    householdId: 'hh',
    name: 'Rice',
    quantity: quantity,
    unit: unit,
    lowStockThreshold: lowStockThreshold,
    lowStockUnit: lowStockUnit,
    availabilityStatus: availabilityStatus,
    expiryDate: expiryDate,
  );
}

void main() {
  group('stock tracking', () {
    test('isOutOfStock when quantity is zero', () {
      expect(_item(quantity: 0).isOutOfStock, isTrue);
    });

    test('isLowStock compares converted units', () {
      final item = _item(
        quantity: 0.5,
        unit: 'kg',
        lowStockThreshold: 600,
        lowStockUnit: 'g',
      );
      expect(item.isLowStock, isTrue);
    });

    test('isLowStock false without threshold', () {
      expect(_item(quantity: 0.1).isLowStock, isFalse);
    });

    test('manual attention bypasses auto stock', () {
      final item = _item(
        quantity: 10,
        availabilityStatus: PantryAvailability.warning,
      );
      expect(item.usesAutoStockTracking, isFalse);
      expect(item.hasManualAttention, isTrue);
      expect(item.needsAttention, isTrue);
    });
  });

  group('attentionLabel', () {
    test('out of stock label', () {
      expect(_item(quantity: 0).attentionLabel, AppStrings.outOfStock);
    });

    test('manual warning label', () {
      expect(
        _item(availabilityStatus: PantryAvailability.emergency).attentionLabel,
        AppStrings.availabilityEmergency,
      );
    });

    test('auto tracking label when fine', () {
      expect(
        _item(availabilityStatus: PantryAvailability.fine).attentionLabel,
        AppStrings.availabilityFine,
      );
    });
  });

  group('expiry', () {
    test('isExpiringSoon within 3 days', () {
      final soon = DateTime.now().add(const Duration(days: 2));
      expect(_item(expiryDate: soon).isExpiringSoon, isTrue);
    });

    test('isExpired for past date', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      expect(_item(expiryDate: past).isExpired, isTrue);
    });
  });

  group('serialization', () {
    test('fromJson parses fields', () {
      final item = PantryItem.fromJson({
        'id': 'p1',
        'household_id': 'hh',
        'name': 'Sugar',
        'quantity': 2.5,
        'unit': 'kg',
        'low_stock_threshold': 500,
        'low_stock_unit': 'g',
        'brand': '  Tata  ',
      });
      expect(item.quantity, 2.5);
      expect(item.brandLabel, 'Tata');
    });

    test('toInsertJson omits low stock unit without threshold', () {
      final json = _item().toInsertJson('hh', 'u1');
      expect(json['low_stock_unit'], isNull);
    });

    test('copyWith can clear availability status', () {
      final updated = _item(availabilityStatus: PantryAvailability.fine)
          .copyWith(clearAvailabilityStatus: true);
      expect(updated.availabilityStatus, isNull);
    });
  });

  group('StockEvent.fromJson', () {
    test('parses stock event', () {
      final event = StockEvent.fromJson({
        'id': 'e1',
        'item_id': 'p1',
        'delta': -0.5,
        'reason': 'used',
        'created_at': '2026-07-08T10:00:00Z',
      });
      expect(event.delta, -0.5);
      expect(event.reason, 'used');
    });
  });
}
