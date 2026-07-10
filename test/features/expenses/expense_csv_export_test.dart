import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/features/expenses/utils/expense_csv_export.dart';
import 'package:myplanr/shared/models/expense.dart';

Expense _expense({
  required String id,
  MoneyEntryType entryType = MoneyEntryType.expense,
  String title = 'Test',
  double amount = 100,
  String? note,
  String? categoryName,
  String? familyMemberName,
  String? incomeSource,
  DateTime? expenseDate,
}) {
  return Expense(
    id: id,
    householdId: 'hh-1',
    categoryId: 'cat-1',
    amount: amount,
    title: title,
    expenseDate: expenseDate ?? DateTime(2026, 7, 8),
    entryType: entryType,
    note: note,
    categoryName: categoryName,
    familyMemberName: familyMemberName,
    incomeSource: incomeSource,
  );
}

void main() {
  group('ExpenseCsvExport.build', () {
    test('includes header, period label, and column headers', () {
      final csv = ExpenseCsvExport.build(
        entries: [],
        periodLabel: 'This month',
      );
      expect(csv, startsWith('MyPlanr money report,This month\n'));
      expect(
        csv,
        contains(
          'entry_type,family_member,income_source,category,amount,date,title,note',
        ),
      );
    });

    test('adds truncation note when truncated', () {
      final csv = ExpenseCsvExport.build(
        entries: [],
        periodLabel: 'July',
        truncated: true,
      );
      expect(csv, contains('Note,Export limited to 5000 rows'));
    });

    test('omits truncation note by default', () {
      final csv = ExpenseCsvExport.build(
        entries: [],
        periodLabel: 'July',
      );
      expect(csv, isNot(contains('Export limited')));
    });

    test('maps expense row fields', () {
      final csv = ExpenseCsvExport.build(
        entries: [
          _expense(
            id: 'e1',
            title: 'Groceries',
            amount: 250.5,
            categoryName: 'Food',
            note: 'Weekly shop',
          ),
        ],
        periodLabel: 'Today',
      );
      expect(
        csv,
        contains('expense,,,Food,250.50,2026-07-08,Groceries,Weekly shop'),
      );
    });

    test('maps income row with member and source', () {
      final csv = ExpenseCsvExport.build(
        entries: [
          _expense(
            id: 'i1',
            entryType: MoneyEntryType.income,
            title: 'Salary',
            incomeSource: '  Acme Corp  ',
            familyMemberName: 'Alex',
            categoryName: 'Salary',
            amount: 50000,
          ),
        ],
        periodLabel: 'Month',
      );
      expect(csv, contains('income,Alex,Acme Corp,Salary,50000.00'));
    });

    test('uses title as income source when income_source is empty', () {
      final csv = ExpenseCsvExport.build(
        entries: [
          _expense(
            id: 'i2',
            entryType: MoneyEntryType.income,
            title: 'Freelance',
            familyMemberName: 'Alex',
          ),
        ],
        periodLabel: 'Month',
      );
      expect(csv, contains('income,Alex,Freelance,'));
    });

    test('escapes commas in title', () {
      final csv = ExpenseCsvExport.build(
        entries: [_expense(id: 'e1', title: 'Rent, utilities')],
        periodLabel: 'Month',
      );
      expect(csv, contains('"Rent, utilities"'));
    });

    test('escapes double quotes in note', () {
      final csv = ExpenseCsvExport.build(
        entries: [_expense(id: 'e1', note: 'Paid "on time"')],
        periodLabel: 'Month',
      );
      expect(csv, contains('"Paid ""on time"""'));
    });

    test('escapes newlines in fields', () {
      final csv = ExpenseCsvExport.build(
        entries: [_expense(id: 'e1', note: 'Line1\nLine2')],
        periodLabel: 'Month',
      );
      expect(csv, contains('"Line1\nLine2"'));
    });

    test('exports multiple entries in order', () {
      final csv = ExpenseCsvExport.build(
        entries: [
          _expense(id: 'e1', title: 'First'),
          _expense(id: 'e2', title: 'Second'),
        ],
        periodLabel: 'Week',
      );
      final lines = csv.trim().split('\n');
      expect(lines[2], contains('First'));
      expect(lines[3], contains('Second'));
    });
  });
}
