/// Trims a Supabase range response to [limit] items and sets [hasMore].
List<T> parsePaginatedRows<T>(
  dynamic data,
  int limit,
  T Function(Map<String, dynamic> json) fromJson, {
  required void Function(bool hasMore, List<T> items) result,
}) {
  final rows = (data as List)
      .map((e) => fromJson(e as Map<String, dynamic>))
      .toList();
  final hasMore = rows.length > limit;
  final items = hasMore ? rows.sublist(0, limit) : rows;
  result(hasMore, items);
  return items;
}

class PaginatedParseResult<T> {
  const PaginatedParseResult({required this.items, required this.hasMore});

  final List<T> items;
  final bool hasMore;
}

PaginatedParseResult<T> parsePaginatedPage<T>(
  dynamic data,
  int limit,
  T Function(Map<String, dynamic> json) fromJson,
) {
  final rows = (data as List)
      .map((e) => fromJson(e as Map<String, dynamic>))
      .toList();
  final hasMore = rows.length > limit;
  return PaginatedParseResult(
    items: hasMore ? rows.sublist(0, limit) : rows,
    hasMore: hasMore,
  );
}
