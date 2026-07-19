import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/models/expense.dart';

void main() {
  group('MoneyEntryType', () {
    test('dbValue matches enum name', () {
      expect(MoneyEntryType.expense.dbValue, 'expense');
      expect(MoneyEntryType.income.dbValue, 'income');
    });

    test('fromDb maps income string', () {
      expect(MoneyEntryType.fromDb('income'), MoneyEntryType.income);
    });

    test('fromDb defaults unknown values to expense', () {
      expect(MoneyEntryType.fromDb(null), MoneyEntryType.expense);
      expect(MoneyEntryType.fromDb('expense'), MoneyEntryType.expense);
      expect(MoneyEntryType.fromDb('other'), MoneyEntryType.expense);
    });
  });

  group('MoneyScope', () {
    test('dbValue matches enum name', () {
      expect(MoneyScope.personal.dbValue, 'personal');
      expect(MoneyScope.household.dbValue, 'household');
    });

    test('fromDb maps personal string', () {
      expect(MoneyScope.fromDb('personal'), MoneyScope.personal);
    });

    test('fromDb defaults unknown/null to household', () {
      expect(MoneyScope.fromDb(null), MoneyScope.household);
      expect(MoneyScope.fromDb('household'), MoneyScope.household);
      expect(MoneyScope.fromDb('other'), MoneyScope.household);
    });
  });

  group('ExpenseCategory', () {
    test('isExpenseCategory for expense kind', () {
      const cat = ExpenseCategory(id: '1', name: 'Food', categoryKind: 'expense');
      expect(cat.isExpenseCategory, isTrue);
      expect(cat.isIncomeCategory, isFalse);
    });

    test('isIncomeCategory for income kind', () {
      const cat = ExpenseCategory(id: '1', name: 'Salary', categoryKind: 'income');
      expect(cat.isIncomeCategory, isTrue);
      expect(cat.isExpenseCategory, isFalse);
    });

    test('both kind matches expense and income', () {
      const cat = ExpenseCategory(id: '1', name: 'Refund', categoryKind: 'both');
      expect(cat.isExpenseCategory, isTrue);
      expect(cat.isIncomeCategory, isTrue);
    });

    test('fromJson defaults categoryKind to expense', () {
      final cat = ExpenseCategory.fromJson({'id': 'c1', 'name': 'Misc'});
      expect(cat.categoryKind, 'expense');
    });

    test('fromJson reads category_kind', () {
      final cat = ExpenseCategory.fromJson({
        'id': 'c2',
        'name': 'Salary',
        'category_kind': 'income',
      });
      expect(cat.id, 'c2');
      expect(cat.name, 'Salary');
      expect(cat.categoryKind, 'income');
    });
  });

  group('Expense computed properties', () {
    test('hasGroup when groupId is set', () {
      final expense = Expense(
        id: 'e1',
        householdId: 'hh',
        categoryId: 'c1',
        amount: 10,
        title: 'Dinner',
        expenseDate: DateTime(2026, 7, 8),
        groupId: 'g1',
      );
      expect(expense.hasGroup, isTrue);
      expect(expense.isIncome, isFalse);
    });

    test('isIncome for income entry type', () {
      final expense = Expense(
        id: 'i1',
        householdId: 'hh',
        categoryId: 'c1',
        amount: 1000,
        title: 'Salary',
        expenseDate: DateTime(2026, 7, 8),
        entryType: MoneyEntryType.income,
      );
      expect(expense.isIncome, isTrue);
    });

    test('displaySource prefers trimmed incomeSource', () {
      final expense = Expense(
        id: 'i1',
        householdId: 'hh',
        categoryId: 'c1',
        amount: 1000,
        title: 'Fallback',
        expenseDate: DateTime(2026, 7, 8),
        entryType: MoneyEntryType.income,
        incomeSource: '  Freelance  ',
      );
      expect(expense.displaySource, 'Freelance');
    });

    test('displaySource falls back to title', () {
      final expense = Expense(
        id: 'i1',
        householdId: 'hh',
        categoryId: 'c1',
        amount: 1000,
        title: 'Bonus',
        expenseDate: DateTime(2026, 7, 8),
        entryType: MoneyEntryType.income,
      );
      expect(expense.displaySource, 'Bonus');
    });

    test('displaySource falls back to title when incomeSource is blank', () {
      final expense = Expense(
        id: 'i1',
        householdId: 'hh',
        categoryId: 'c1',
        amount: 1000,
        title: 'Bonus',
        expenseDate: DateTime(2026, 7, 8),
        entryType: MoneyEntryType.income,
        incomeSource: '   ',
      );
      expect(expense.displaySource, 'Bonus');
    });
  });

  group('Expense.fromJson', () {
    test('parses expense with nested joins and splits', () {
      final expense = Expense.fromJson({
        'id': 'e1',
        'household_id': 'hh-1',
        'category_id': 'cat-1',
        'amount': 99.5,
        'title': 'Groceries',
        'expense_date': '2026-07-08',
        'entry_type': 'expense',
        'note': 'Weekly',
        'group_id': 'g1',
        'paid_by_member_id': 'm1',
        'expense_categories': {'name': 'Food'},
        'household_family_members': {'display_name': 'Alex'},
        'expense_groups': {'name': 'Roommates'},
        'paid_by_member': {'display_name': 'Alex'},
        'expense_splits': [
          {
            'id': 's1',
            'expense_id': 'e1',
            'group_member_id': 'gm1',
            'share_type': 'equal',
            'owed_amount': 49.75,
          },
        ],
      });

      expect(expense.id, 'e1');
      expect(expense.amount, 99.5);
      expect(expense.entryType, MoneyEntryType.expense);
      expect(expense.categoryName, 'Food');
      expect(expense.familyMemberName, 'Alex');
      expect(expense.groupName, 'Roommates');
      expect(expense.paidByMemberName, 'Alex');
      expect(expense.splits, hasLength(1));
      expect(expense.scope, MoneyScope.household);
    });

    test('parses personal scope', () {
      final expense = Expense.fromJson({
        'id': 'e2',
        'household_id': 'hh',
        'category_id': 'c1',
        'amount': 5,
        'title': 'Private',
        'expense_date': '2026-07-08',
        'scope': 'personal',
      });
      expect(expense.scope, MoneyScope.personal);
    });

    test('defaults scope to household when missing', () {
      final expense = Expense.fromJson({
        'id': 'e3',
        'household_id': 'hh',
        'category_id': 'c1',
        'amount': 5,
        'title': 'Shared',
        'expense_date': '2026-07-08',
      });
      expect(expense.scope, MoneyScope.household);
    });

    test('parses income entry fields', () {
      final expense = Expense.fromJson({
        'id': 'i1',
        'household_id': 'hh-1',
        'category_id': 'cat-2',
        'amount': 50000,
        'title': 'Salary',
        'expense_date': '2026-07-01',
        'entry_type': 'income',
        'family_member_id': 'fm-1',
        'income_source': 'Acme',
      });
      expect(expense.isIncome, isTrue);
      expect(expense.familyMemberId, 'fm-1');
      expect(expense.incomeSource, 'Acme');
      expect(expense.splits, isEmpty);
    });

    test('defaults entry_type to expense when missing', () {
      final expense = Expense.fromJson({
        'id': 'e1',
        'household_id': 'hh',
        'category_id': 'c1',
        'amount': 1,
        'title': 'X',
        'expense_date': '2026-07-01',
      });
      expect(expense.entryType, MoneyEntryType.expense);
    });
  });

  group('summary models fromJson', () {
    test('ExpenseSummaryRow', () {
      final row = ExpenseSummaryRow.fromJson({
        'category_id': 'c1',
        'category_name': 'Food',
        'total_amount': 123.45,
      });
      expect(row.categoryId, 'c1');
      expect(row.categoryName, 'Food');
      expect(row.totalAmount, 123.45);
    });

    test('MoneySummary', () {
      final summary = MoneySummary.fromJson({
        'total_spent': 1000,
        'total_earned': 5000,
        'net_amount': 4000,
      });
      expect(summary.totalSpent, 1000);
      expect(summary.totalEarned, 5000);
      expect(summary.netAmount, 4000);
    });

    test('MemberIncomeSummary', () {
      final summary = MemberIncomeSummary.fromJson({
        'family_member_id': 'fm-1',
        'member_name': 'Alex',
        'earned_total': 2500,
      });
      expect(summary.familyMemberId, 'fm-1');
      expect(summary.memberName, 'Alex');
      expect(summary.earnedTotal, 2500);
    });

    test('MemberIncomeSourceSummary', () {
      final summary = MemberIncomeSourceSummary.fromJson({
        'income_source': 'Freelance',
        'earned_total': 800,
      });
      expect(summary.incomeSource, 'Freelance');
      expect(summary.earnedTotal, 800);
    });
  });
}
