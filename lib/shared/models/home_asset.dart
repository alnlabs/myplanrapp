import '../constants/asset_constants.dart';

class HomeAsset {
  const HomeAsset({
    required this.id,
    required this.householdId,
    required this.name,
    required this.category,
    required this.itemKind,
    required this.status,
    this.createdBy,
    this.description,
    this.location,
    this.acquisitionType,
    this.purchaseDate,
    this.purchaseAmount,
    this.vendorName,
    this.vendorUrl,
    this.orderReference,
    this.warrantyStart,
    this.warrantyEnd,
    this.warrantyProvider,
    this.warrantyNotes,
    this.expiryDate,
    this.usedByMemberId,
  });

  final String id;
  final String householdId;
  final String? createdBy;
  final String name;
  final String? description;
  final String category;
  final String itemKind;
  final String status;
  final String? location;
  final String? acquisitionType;
  final DateTime? purchaseDate;
  final double? purchaseAmount;
  final String? vendorName;
  final String? vendorUrl;
  final String? orderReference;
  final DateTime? warrantyStart;
  final DateTime? warrantyEnd;
  final String? warrantyProvider;
  final String? warrantyNotes;
  final DateTime? expiryDate;
  final String? usedByMemberId;

  WarrantyStatus get warrantyStatus => warrantyStatusFor(warrantyEnd);

  factory HomeAsset.fromJson(Map<String, dynamic> json) {
    return HomeAsset(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      createdBy: json['created_by'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      itemKind: json['item_kind'] as String,
      status: json['status'] as String,
      location: json['location'] as String?,
      acquisitionType: json['acquisition_type'] as String?,
      purchaseDate: _parseDate(json['purchase_date']),
      purchaseAmount: (json['purchase_amount'] as num?)?.toDouble(),
      vendorName: json['vendor_name'] as String?,
      vendorUrl: json['vendor_url'] as String?,
      orderReference: json['order_reference'] as String?,
      warrantyStart: _parseDate(json['warranty_start']),
      warrantyEnd: _parseDate(json['warranty_end']),
      warrantyProvider: json['warranty_provider'] as String?,
      warrantyNotes: json['warranty_notes'] as String?,
      expiryDate: _parseDate(json['expiry_date']),
      usedByMemberId: json['used_by_member_id'] as String?,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.parse(value as String);
  }

  Map<String, dynamic> toJson(String householdId, String? userId) {
    return {
      'household_id': householdId,
      'created_by': userId,
      'name': name,
      'description': description,
      'category': category,
      'item_kind': itemKind,
      'status': status,
      'location': location,
      'acquisition_type': acquisitionType,
      'purchase_date': purchaseDate?.toIso8601String().split('T').first,
      'purchase_amount': purchaseAmount,
      'vendor_name': vendorName,
      'vendor_url': vendorUrl,
      'order_reference': orderReference,
      'warranty_start': warrantyStart?.toIso8601String().split('T').first,
      'warranty_end': warrantyEnd?.toIso8601String().split('T').first,
      'warranty_provider': warrantyProvider,
      'warranty_notes': warrantyNotes,
      'expiry_date': expiryDate?.toIso8601String().split('T').first,
      'used_by_member_id': usedByMemberId,
    };
  }
}

class AssetServiceRecord {
  const AssetServiceRecord({
    required this.id,
    required this.assetId,
    required this.householdId,
    required this.serviceType,
    required this.serviceDate,
    this.createdBy,
    this.shopName,
    this.shopAddress,
    this.shopPhone,
    this.platformName,
    this.agentName,
    this.bookingRef,
    this.cost,
    this.notes,
  });

  final String id;
  final String assetId;
  final String householdId;
  final String? createdBy;
  final String serviceType;
  final DateTime serviceDate;
  final String? shopName;
  final String? shopAddress;
  final String? shopPhone;
  final String? platformName;
  final String? agentName;
  final String? bookingRef;
  final double? cost;
  final String? notes;

  factory AssetServiceRecord.fromJson(Map<String, dynamic> json) {
    return AssetServiceRecord(
      id: json['id'] as String,
      assetId: json['asset_id'] as String,
      householdId: json['household_id'] as String,
      createdBy: json['created_by'] as String?,
      serviceType: json['service_type'] as String,
      serviceDate: DateTime.parse(json['service_date'] as String),
      shopName: json['shop_name'] as String?,
      shopAddress: json['shop_address'] as String?,
      shopPhone: json['shop_phone'] as String?,
      platformName: json['platform_name'] as String?,
      agentName: json['agent_name'] as String?,
      bookingRef: json['booking_ref'] as String?,
      cost: (json['cost'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson(String assetId, String householdId, String? userId) {
    return {
      'asset_id': assetId,
      'household_id': householdId,
      'created_by': userId,
      'service_type': serviceType,
      'service_date': serviceDate.toIso8601String().split('T').first,
      'shop_name': shopName,
      'shop_address': shopAddress,
      'shop_phone': shopPhone,
      'platform_name': platformName,
      'agent_name': agentName,
      'booking_ref': bookingRef,
      'cost': cost,
      'notes': notes,
    };
  }
}
