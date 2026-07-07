class PantryItem {
  const PantryItem({
    required this.id,
    required this.householdId,
    required this.name,
    required this.quantity,
    required this.unit,
    this.lowStockThreshold,
    this.category,
    this.expiryDate,
    this.updatedAt,
  });

  final String id;
  final String householdId;
  final String name;
  final double quantity;
  final String unit;
  final double? lowStockThreshold;
  final String? category;
  final DateTime? expiryDate;
  final DateTime? updatedAt;

  bool get isLowStock =>
      lowStockThreshold != null && quantity <= lowStockThreshold!;

  bool get isOutOfStock => quantity <= 0;

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final days = expiryDate!.difference(DateTime.now()).inDays;
    return days >= 0 && days <= 3;
  }

  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  factory PantryItem.fromJson(Map<String, dynamic> json) {
    return PantryItem(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      lowStockThreshold: json['low_stock_threshold'] != null
          ? (json['low_stock_threshold'] as num).toDouble()
          : null,
      category: json['category'] as String?,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson(String householdId, String? userId) {
    return {
      'household_id': householdId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'low_stock_threshold': lowStockThreshold,
      'category': category,
      'expiry_date': expiryDate?.toIso8601String().split('T').first,
      'created_by': userId,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'low_stock_threshold': lowStockThreshold,
      'category': category,
      'expiry_date': expiryDate?.toIso8601String().split('T').first,
    };
  }
}

class StockEvent {
  const StockEvent({
    required this.id,
    required this.itemId,
    required this.delta,
    required this.reason,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String itemId;
  final double delta;
  final String reason;
  final String? note;
  final DateTime createdAt;

  factory StockEvent.fromJson(Map<String, dynamic> json) {
    return StockEvent(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      delta: (json['delta'] as num).toDouble(),
      reason: json['reason'] as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
