/// Where a detected receipt line item should go when applied.
enum ReceiptLineDestination { pantry, shopping, ignore }

extension ReceiptLineDestinationX on ReceiptLineDestination {
  String get dbValue => name;

  static ReceiptLineDestination fromValue(String? value) {
    return switch (value) {
      'pantry' => ReceiptLineDestination.pantry,
      'shopping' => ReceiptLineDestination.shopping,
      'ignore' => ReceiptLineDestination.ignore,
      _ => ReceiptLineDestination.pantry,
    };
  }
}

/// Full result of analyzing a receipt image server-side. The edge function does
/// vision extraction, maps merchant/category, and matches line items against the
/// household pantry so the app can render a "what goes where" preview.
class ReceiptAnalysis {
  const ReceiptAnalysis({
    required this.fingerprint,
    this.merchant,
    this.purchasedAt,
    this.total,
    this.currency,
    this.suggestedCategoryId,
    this.suggestedCategoryName,
    this.alreadyProcessed = false,
    this.existingReceiptId,
    this.lines = const [],
  });

  final String fingerprint;
  final String? merchant;
  final DateTime? purchasedAt;
  final double? total;
  final String? currency;
  final String? suggestedCategoryId;
  final String? suggestedCategoryName;

  /// True when a receipt with the same fingerprint was already processed for
  /// this household. The UI warns instead of silently re-adding.
  final bool alreadyProcessed;
  final String? existingReceiptId;

  final List<ReceiptLine> lines;

  factory ReceiptAnalysis.fromJson(Map<String, dynamic> json) {
    final rawLines = (json['items'] ?? json['lines']) as List<dynamic>?;
    return ReceiptAnalysis(
      fingerprint: json['fingerprint'] as String? ?? '',
      merchant: _asString(json['merchant']),
      purchasedAt: _asDate(json['purchasedAt'] ?? json['purchased_at']),
      total: _asDouble(json['total']),
      currency: _asString(json['currency']),
      suggestedCategoryId:
          _asString(json['suggestedCategoryId'] ?? json['suggested_category_id']),
      suggestedCategoryName: _asString(
          json['suggestedCategoryName'] ?? json['suggested_category_name']),
      alreadyProcessed:
          (json['alreadyProcessed'] ?? json['already_processed']) == true,
      existingReceiptId:
          _asString(json['existingReceiptId'] ?? json['existing_receipt_id']),
      lines: rawLines == null
          ? const []
          : rawLines
              .whereType<Map<String, dynamic>>()
              .map(ReceiptLine.fromJson)
              .toList(),
    );
  }
}

/// A single detected line item plus how it maps into MyPlanr.
class ReceiptLine {
  const ReceiptLine({
    required this.lineIndex,
    required this.name,
    this.rawText,
    this.qty,
    this.unit,
    this.unitPrice,
    this.lineTotal,
    this.destination = ReceiptLineDestination.pantry,
    this.matchedItemId,
    this.matchedItemName,
    this.matchConfidence = 0,
  });

  final int lineIndex;
  final String name;
  final String? rawText;
  final double? qty;
  final String? unit;
  final double? unitPrice;
  final double? lineTotal;
  final ReceiptLineDestination destination;

  /// Set when this line matches an existing pantry item -> restock instead of
  /// creating a duplicate.
  final String? matchedItemId;
  final String? matchedItemName;
  final double matchConfidence;

  /// A pantry line that matches an existing item restocks it; otherwise it
  /// creates a new item. Shopping/ignore lines are neither.
  bool get isRestock =>
      destination == ReceiptLineDestination.pantry && matchedItemId != null;

  bool get isCreate =>
      destination == ReceiptLineDestination.pantry && matchedItemId == null;

  factory ReceiptLine.fromJson(Map<String, dynamic> json) {
    return ReceiptLine(
      lineIndex: (json['lineIndex'] ?? json['line_index'] ?? 0) as int,
      name: _asString(json['name']) ?? _asString(json['rawText']) ?? 'Item',
      rawText: _asString(json['rawText'] ?? json['raw_text']),
      qty: _asDouble(json['qty'] ?? json['quantity']),
      unit: _asString(json['unit']),
      unitPrice: _asDouble(json['unitPrice'] ?? json['unit_price']),
      lineTotal: _asDouble(json['lineTotal'] ?? json['line_total']),
      destination: ReceiptLineDestinationX.fromValue(
          _asString(json['destination'])),
      matchedItemId:
          _asString(json['matchedItemId'] ?? json['matched_item_id']),
      matchedItemName:
          _asString(json['matchedItemName'] ?? json['matched_item_name']),
      matchConfidence:
          _asDouble(json['matchConfidence'] ?? json['match_confidence']) ?? 0,
    );
  }

  ReceiptLine copyWith({
    int? lineIndex,
    String? name,
    double? qty,
    String? unit,
    ReceiptLineDestination? destination,
    String? matchedItemId,
    String? matchedItemName,
    bool clearMatch = false,
  }) {
    return ReceiptLine(
      lineIndex: lineIndex ?? this.lineIndex,
      name: name ?? this.name,
      rawText: rawText,
      qty: qty ?? this.qty,
      unit: unit ?? this.unit,
      unitPrice: unitPrice,
      lineTotal: lineTotal,
      destination: destination ?? this.destination,
      matchedItemId: clearMatch ? null : (matchedItemId ?? this.matchedItemId),
      matchedItemName:
          clearMatch ? null : (matchedItemName ?? this.matchedItemName),
      matchConfidence: matchConfidence,
    );
  }
}

String? _asString(Object? value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

double? _asDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _asDate(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
