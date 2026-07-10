import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/models/recurring_money_rule.dart';

RecurringMoneyRule _rule({
  String entryType = 'expense',
  String title = 'Rent',
  String? incomeSource,
  DateTime? nextDueDate,
  DateTime? snoozeUntil,
  bool isActive = true,
  bool autoLog = false,
}) {
  return RecurringMoneyRule(
    id: 'r1',
    householdId: 'hh-1',
    entryType: entryType,
    title: title,
    amount: 1000,
    categoryId: 'cat-1',
    frequency: 'monthly',
    intervalCount: 1,
    startDate: DateTime(2026, 1, 1),
    nextDueDate: nextDueDate ?? DateTime(2026, 7, 1),
    incomeSource: incomeSource,
    snoozeUntil: snoozeUntil,
    isActive: isActive,
    autoLog: autoLog,
  );
}

void main() {
  group('entry type helpers', () {
    test('isIncome and isExpense', () {
      expect(_rule(entryType: 'income').isIncome, isTrue);
      expect(_rule(entryType: 'income').isExpense, isFalse);
      expect(_rule(entryType: 'expense').isExpense, isTrue);
      expect(_rule(entryType: 'expense').isIncome, isFalse);
    });
  });

  group('displayLabel', () {
    test('uses trimmed incomeSource for income rules', () {
      final rule = _rule(
        entryType: 'income',
        title: 'Fallback',
        incomeSource: '  Salary  ',
      );
      expect(rule.displayLabel, 'Salary');
    });

    test('uses title when income source is empty', () {
      final rule = _rule(
        entryType: 'income',
        title: 'Freelance',
        incomeSource: '',
      );
      expect(rule.displayLabel, 'Freelance');
    });

    test('uses title for expense rules', () {
      final rule = _rule(entryType: 'expense', title: 'Rent');
      expect(rule.displayLabel, 'Rent');
    });
  });

  group('isDue', () {
    test('is due when next due date is today or past', () {
      final today = DateTime.now();
      final rule = _rule(
        nextDueDate: DateTime(today.year, today.month, today.day),
      );
      expect(rule.isDue, isTrue);
    });

    test('is not due when next due date is in the future', () {
      final future = DateTime.now().add(const Duration(days: 5));
      final rule = _rule(nextDueDate: future);
      expect(rule.isDue, isFalse);
    });

    test('snooze blocks due until snooze date passes', () {
      final today = DateTime.now();
      final rule = _rule(
        nextDueDate: today.subtract(const Duration(days: 3)),
        snoozeUntil: today.add(const Duration(days: 2)),
      );
      expect(rule.isDue, isFalse);
    });

    test('is due after snooze date when still overdue', () {
      final today = DateTime.now();
      final rule = _rule(
        nextDueDate: today.subtract(const Duration(days: 5)),
        snoozeUntil: today.subtract(const Duration(days: 1)),
      );
      expect(rule.isDue, isTrue);
    });
  });

  group('fromJson', () {
    test('parses expense rule with nested joins and defaults', () {
      final rule = RecurringMoneyRule.fromJson({
        'id': 'r1',
        'household_id': 'hh-1',
        'entry_type': 'expense',
        'title': 'Netflix',
        'amount': 499,
        'category_id': 'cat-1',
        'frequency': 'monthly',
        'start_date': '2026-01-01',
        'next_due_date': '2026-07-05',
        'auto_log': true,
        'group_id': 'g1',
        'paid_by_member_id': 'gm1',
        'subscription_id': 'sub1',
        'expense_categories': {'name': 'Subscriptions'},
        'expense_groups': {'name': 'Household'},
        'subscriptions': {'name': 'Netflix'},
      });

      expect(rule.entryType, 'expense');
      expect(rule.title, 'Netflix');
      expect(rule.amount, 499);
      expect(rule.autoLog, isTrue);
      expect(rule.groupId, 'g1');
      expect(rule.paidByMemberId, 'gm1');
      expect(rule.subscriptionId, 'sub1');
      expect(rule.categoryName, 'Subscriptions');
      expect(rule.groupName, 'Household');
      expect(rule.subscriptionName, 'Netflix');
      expect(rule.intervalCount, 1);
      expect(rule.isActive, isTrue);
    });

    test('parses income rule with member join', () {
      final rule = RecurringMoneyRule.fromJson({
        'id': 'r2',
        'household_id': 'hh-1',
        'title': 'Salary',
        'amount': 50000,
        'category_id': 'cat-2',
        'frequency': 'monthly',
        'start_date': '2026-01-01',
        'next_due_date': '2026-07-01',
        'income_source': 'Acme',
        'family_member_id': 'fm-1',
        'household_family_members': {'display_name': 'Alex'},
      });

      expect(rule.entryType, 'income');
      expect(rule.incomeSource, 'Acme');
      expect(rule.familyMemberId, 'fm-1');
      expect(rule.familyMemberName, 'Alex');
    });

    test('defaults entry_type to income when missing', () {
      final rule = RecurringMoneyRule.fromJson({
        'id': 'r3',
        'household_id': 'hh',
        'title': 'X',
        'amount': 1,
        'category_id': 'c',
        'frequency': 'monthly',
        'start_date': '2026-01-01',
        'next_due_date': '2026-07-01',
      });
      expect(rule.entryType, 'income');
    });

    test('parses optional date and schedule fields', () {
      final rule = RecurringMoneyRule.fromJson({
        'id': 'r4',
        'household_id': 'hh',
        'entry_type': 'expense',
        'title': 'Insurance',
        'amount': 1200,
        'category_id': 'c',
        'frequency': 'yearly',
        'interval_count': 2,
        'day_of_month': 15,
        'day_of_week': 3,
        'month_of_year': 6,
        'start_date': '2026-01-01',
        'end_date': '2027-01-01',
        'next_due_date': '2026-06-15',
        'is_active': false,
        'snooze_until': '2026-08-01',
        'note': 'Annual premium',
      });

      expect(rule.intervalCount, 2);
      expect(rule.dayOfMonth, 15);
      expect(rule.dayOfWeek, 3);
      expect(rule.monthOfYear, 6);
      expect(rule.endDate, DateTime(2027, 1, 1));
      expect(rule.isActive, isFalse);
      expect(rule.snoozeUntil, DateTime(2026, 8, 1));
      expect(rule.note, 'Annual premium');
    });
  });
}
