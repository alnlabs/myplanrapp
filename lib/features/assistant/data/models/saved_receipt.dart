/// A persisted receipt row (list view). Line items are loaded separately when
/// the user opens the detail.
class SavedReceipt {
  const SavedReceipt({
    required this.id,
    required this.status,
    this.merchant,
    this.purchasedAt,
    this.total,
    this.currency,
    this.createdAt,
    this.itemCount = 0,
  });

  final String id;
  final String status; // 'pending' | 'processed'
  final String? merchant;
  final DateTime? purchasedAt;
  final double? total;
  final String? currency;
  final DateTime? createdAt;
  final int itemCount;

  bool get isProcessed => status == 'processed';

  factory SavedReceipt.fromJson(Map<String, dynamic> json) {
    // PostgREST returns the aggregate as `receipt_line_items: [{count: n}]`.
    int count = 0;
    final rel = json['receipt_line_items'];
    if (rel is List && rel.isNotEmpty) {
      final first = rel.first;
      if (first is Map && first['count'] is num) {
        count = (first['count'] as num).toInt();
      }
    }

    double? asDouble(Object? v) =>
        v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));
    DateTime? asDate(Object? v) => v == null ? null : DateTime.tryParse('$v');

    return SavedReceipt(
      id: json['id'] as String,
      status: (json['status'] as String?) ?? 'pending',
      merchant: json['merchant'] as String?,
      purchasedAt: asDate(json['purchased_at']),
      total: asDouble(json['total']),
      currency: json['currency'] as String?,
      createdAt: asDate(json['created_at']),
      itemCount: count,
    );
  }
}
