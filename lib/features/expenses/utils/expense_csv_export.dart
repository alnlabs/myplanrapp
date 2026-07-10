import '../../../shared/models/expense.dart';

class ExpenseCsvExport {
  ExpenseCsvExport._();

  static String build({
    required List<Expense> entries,
    required String periodLabel,
    bool truncated = false,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('MyPlanr money report,$periodLabel');
    if (truncated) {
      buffer.writeln('Note,Export limited to 5000 rows');
    }
    buffer.writeln(
      'entry_type,family_member,income_source,category,amount,date,title,note',
    );
    for (final entry in entries) {
      buffer.writeln([
        entry.entryType.dbValue,
        _escape(entry.familyMemberName ?? ''),
        _escape(entry.isIncome ? entry.displaySource : ''),
        _escape(entry.categoryName ?? ''),
        entry.amount.toStringAsFixed(2),
        entry.expenseDate.toIso8601String().split('T').first,
        _escape(entry.title),
        _escape(entry.note ?? ''),
      ].join(','));
    }
    return buffer.toString();
  }

  static String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
