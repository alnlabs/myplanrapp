import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/features/expenses/utils/expense_split_calculator.dart';
import 'package:myplanr/shared/models/expense_group.dart';
import 'package:myplanr/shared/models/expense_split.dart';

void main() {
  group('ExpenseShareType', () {
    test('dbValue matches enum name', () {
      expect(ExpenseShareType.equal.dbValue, 'equal');
      expect(ExpenseShareType.exact.dbValue, 'exact');
      expect(ExpenseShareType.percent.dbValue, 'percent');
    });
  });

  group('splitEqually', () {
    test('returns empty list for no participants', () {
      expect(
        ExpenseSplitCalculator.splitEqually(amount: 100, participantIds: []),
        isEmpty,
      );
    });

    test('splits evenly with remainder to first participants', () {
      final splits = ExpenseSplitCalculator.splitEqually(
        amount: 10,
        participantIds: ['a', 'b', 'c'],
      );
      expect(splits, hasLength(3));
      expect(splits.map((s) => s.owedAmount).fold<double>(0, (a, b) => a + b),
          closeTo(10, 0.001));
      expect(splits[0].owedAmount, 3.34);
      expect(splits[1].owedAmount, 3.33);
      expect(splits[2].owedAmount, 3.33);
      for (final split in splits) {
        expect(split.shareType, 'equal');
      }
    });

    test('payer receives remainder paise first', () {
      final splits = ExpenseSplitCalculator.splitEqually(
        amount: 10,
        participantIds: ['a', 'b', 'c'],
        payerMemberId: 'c',
      );
      final byId = {for (final s in splits) s.groupMemberId: s.owedAmount};
      expect(byId['c'], 3.34);
      expect(byId['a'], 3.33);
      expect(byId['b'], 3.33);
    });

    test('single participant gets full amount', () {
      final splits = ExpenseSplitCalculator.splitEqually(
        amount: 42.5,
        participantIds: ['solo'],
      );
      expect(splits.single.owedAmount, 42.5);
    });
  });

  group('splitByExact', () {
    test('maps each member to exact owed amount', () {
      final splits = ExpenseSplitCalculator.splitByExact(
        amountsByMember: {'a': 60, 'b': 40},
      );
      expect(splits, hasLength(2));
      final a = splits.firstWhere((s) => s.groupMemberId == 'a');
      final b = splits.firstWhere((s) => s.groupMemberId == 'b');
      expect(a.shareType, 'exact');
      expect(a.shareValue, 60);
      expect(a.owedAmount, 60);
      expect(b.owedAmount, 40);
    });
  });

  group('splitByPercent', () {
    test('last participant absorbs rounding remainder', () {
      final splits = ExpenseSplitCalculator.splitByPercent(
        amount: 100,
        percentsByMember: {'a': 33.33, 'b': 33.33, 'c': 33.34},
      );
      final total =
          splits.fold<double>(0, (sum, s) => sum + s.owedAmount);
      expect(total, closeTo(100, 0.001));
      expect(splits.last.groupMemberId, 'c');
      expect(splits.every((s) => s.shareType == 'percent'), isTrue);
    });

    test('two-way split uses exact half', () {
      final splits = ExpenseSplitCalculator.splitByPercent(
        amount: 50,
        percentsByMember: {'a': 50, 'b': 50},
      );
      expect(splits[0].owedAmount, 25);
      expect(splits[1].owedAmount, 25);
    });
  });

  group('sumsToAmount', () {
    test('accepts total within tolerance', () {
      final splits = [
        const ExpenseSplitInput(
          groupMemberId: 'a',
          shareType: 'exact',
          owedAmount: 33.33,
        ),
        const ExpenseSplitInput(
          groupMemberId: 'b',
          shareType: 'exact',
          owedAmount: 33.33,
        ),
        const ExpenseSplitInput(
          groupMemberId: 'c',
          shareType: 'exact',
          owedAmount: 33.34,
        ),
      ];
      expect(ExpenseSplitCalculator.sumsToAmount(splits, 100), isTrue);
    });

    test('rejects total outside tolerance', () {
      final splits = [
        const ExpenseSplitInput(
          groupMemberId: 'a',
          shareType: 'exact',
          owedAmount: 50,
        ),
      ];
      expect(ExpenseSplitCalculator.sumsToAmount(splits, 100), isFalse);
    });
  });

  group('suggestSettlements', () {
    test('returns empty when all balances are settled', () {
      final balances = [
        const ExpenseGroupBalance(
          groupMemberId: 'a',
          displayName: 'Alice',
          paidTotal: 50,
          owedTotal: 50,
          settledIn: 0,
          settledOut: 0,
          netBalance: 0,
        ),
      ];
      expect(ExpenseSplitCalculator.suggestSettlements(balances), isEmpty);
    });

    test('suggests debtor pays creditor', () {
      final balances = [
        const ExpenseGroupBalance(
          groupMemberId: 'a',
          displayName: 'Alice',
          paidTotal: 100,
          owedTotal: 50,
          settledIn: 0,
          settledOut: 0,
          netBalance: 50,
        ),
        const ExpenseGroupBalance(
          groupMemberId: 'b',
          displayName: 'Bob',
          paidTotal: 0,
          owedTotal: 50,
          settledIn: 0,
          settledOut: 0,
          netBalance: -50,
        ),
      ];
      final suggestions =
          ExpenseSplitCalculator.suggestSettlements(balances);
      expect(suggestions, hasLength(1));
      expect(suggestions.single.fromMemberId, 'b');
      expect(suggestions.single.toMemberId, 'a');
      expect(suggestions.single.amount, 50);
    });

    test('handles multiple debtors and creditors', () {
      final balances = [
        const ExpenseGroupBalance(
          groupMemberId: 'a',
          displayName: 'Alice',
          paidTotal: 90,
          owedTotal: 30,
          settledIn: 0,
          settledOut: 0,
          netBalance: 60,
        ),
        const ExpenseGroupBalance(
          groupMemberId: 'b',
          displayName: 'Bob',
          paidTotal: 0,
          owedTotal: 30,
          settledIn: 0,
          settledOut: 0,
          netBalance: -30,
        ),
        const ExpenseGroupBalance(
          groupMemberId: 'c',
          displayName: 'Carol',
          paidTotal: 0,
          owedTotal: 30,
          settledIn: 0,
          settledOut: 0,
          netBalance: -30,
        ),
      ];
      final suggestions =
          ExpenseSplitCalculator.suggestSettlements(balances);
      expect(suggestions, hasLength(2));
      final totalPaid = suggestions.fold<double>(0, (s, e) => s + e.amount);
      expect(totalPaid, closeTo(60, 0.01));
    });

    test('ignores balances within 0.01 tolerance', () {
      final balances = [
        const ExpenseGroupBalance(
          groupMemberId: 'a',
          displayName: 'Alice',
          paidTotal: 50,
          owedTotal: 50,
          settledIn: 0,
          settledOut: 0,
          netBalance: 0.005,
        ),
        const ExpenseGroupBalance(
          groupMemberId: 'b',
          displayName: 'Bob',
          paidTotal: 0,
          owedTotal: 50,
          settledIn: 0,
          settledOut: 0,
          netBalance: -0.005,
        ),
      ];
      expect(ExpenseSplitCalculator.suggestSettlements(balances), isEmpty);
    });
  });
}
