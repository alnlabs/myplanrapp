enum WarrantyStatus { none, valid, expiring, expired }

class AssetCategories {
  AssetCategories._();

  static const electronics = 'electronics';
  static const appliance = 'appliance';
  static const furniture = 'furniture';
  static const cable = 'cable';
  static const other = 'other';

  static const all = [
    (value: electronics, label: 'Electronics'),
    (value: appliance, label: 'Appliances'),
    (value: furniture, label: 'Furniture'),
    (value: cable, label: 'Cables & accessories'),
    (value: other, label: 'Other'),
  ];

  static String labelFor(String value) =>
      all.firstWhere((c) => c.value == value, orElse: () => all.last).label;
}

class AssetKinds {
  AssetKinds._();

  static const permanent = 'permanent';
  static const temporary = 'temporary';
  static const borrowed = 'borrowed';

  static const all = [
    (value: permanent, label: 'Owned — long term'),
    (value: temporary, label: 'Short-term use'),
    (value: borrowed, label: 'Borrowed'),
  ];
}

class AssetStatuses {
  AssetStatuses._();

  static const active = 'active';
  static const underRepair = 'under_repair';
  static const borrowedOut = 'borrowed_out';
  static const disposed = 'disposed';

  static const all = [
    (value: active, label: 'Active'),
    (value: underRepair, label: 'Under repair'),
    (value: borrowedOut, label: 'Borrowed out'),
    (value: disposed, label: 'Disposed'),
  ];

  static String labelFor(String value) =>
      all.firstWhere((s) => s.value == value, orElse: () => all.first).label;
}

class ServiceTypes {
  ServiceTypes._();

  static const shopRepair = 'shop_repair';
  static const thirdParty = 'third_party';
  static const diy = 'diy';

  static const all = [
    (value: shopRepair, label: 'Shop repair'),
    (value: thirdParty, label: 'Third-party service'),
    (value: diy, label: 'DIY'),
  ];
}

WarrantyStatus warrantyStatusFor(DateTime? warrantyEnd) {
  if (warrantyEnd == null) return WarrantyStatus.none;
  final now = DateTime.now();
  final end = DateTime(warrantyEnd.year, warrantyEnd.month, warrantyEnd.day);
  final today = DateTime(now.year, now.month, now.day);
  if (end.isBefore(today)) return WarrantyStatus.expired;
  if (end.difference(today).inDays <= 30) return WarrantyStatus.expiring;
  return WarrantyStatus.valid;
}
