import '../../../shared/models/expense_group.dart';
import '../../../shared/models/expense_split.dart';

enum ExpenseShareType {
  equal,
  exact,
  percent;

  String get dbValue => name;
}

class ExpenseSplitCalculator {
  ExpenseSplitCalculator._();

  static List<ExpenseSplitInput> splitEqually({
    required double amount,
    required List<String> participantIds,
    String payerMemberId = '',
  }) {
    if (participantIds.isEmpty) return [];
    final n = participantIds.length;
    final basePaise = ((amount * 100) / n).floor();
    var remainderPaise = (amount * 100).round() - basePaise * n;

    final ordered = [...participantIds];
    if (payerMemberId.isNotEmpty) {
      ordered.remove(payerMemberId);
      ordered.insert(0, payerMemberId);
    }

    return ordered.map((id) {
      var owedPaise = basePaise;
      if (remainderPaise > 0) {
        owedPaise++;
        remainderPaise--;
      }
      return ExpenseSplitInput(
        groupMemberId: id,
        shareType: ExpenseShareType.equal.dbValue,
        owedAmount: owedPaise / 100,
      );
    }).toList();
  }

  static List<ExpenseSplitInput> splitByExact({
    required Map<String, double> amountsByMember,
  }) {
    return amountsByMember.entries
        .map(
          (e) => ExpenseSplitInput(
            groupMemberId: e.key,
            shareType: ExpenseShareType.exact.dbValue,
            shareValue: e.value,
            owedAmount: e.value,
          ),
        )
        .toList();
  }

  static List<ExpenseSplitInput> splitByPercent({
    required double amount,
    required Map<String, double> percentsByMember,
  }) {
    final entries = percentsByMember.entries.toList();
    final results = <ExpenseSplitInput>[];
    var assigned = 0.0;
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final isLast = i == entries.length - 1;
      final owed = isLast
          ? double.parse((amount - assigned).toStringAsFixed(2))
          : double.parse((amount * entry.value / 100).toStringAsFixed(2));
      assigned += owed;
      results.add(
        ExpenseSplitInput(
          groupMemberId: entry.key,
          shareType: ExpenseShareType.percent.dbValue,
          shareValue: entry.value,
          owedAmount: owed,
        ),
      );
    }
    return results;
  }

  static bool sumsToAmount(List<ExpenseSplitInput> splits, double amount) {
    final total =
        splits.fold<double>(0, (sum, split) => sum + split.owedAmount);
    return (total - amount).abs() <= 0.01;
  }

  static List<SuggestedSettlement> suggestSettlements(
    List<ExpenseGroupBalance> balances,
  ) {
    final debtors = balances
        .where((b) => b.netBalance < -0.01)
        .map(
          (b) => _SettlementParty(
            id: b.groupMemberId,
            name: b.displayName,
            amount: -b.netBalance,
          ),
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final creditors = balances
        .where((b) => b.netBalance > 0.01)
        .map(
          (b) => _SettlementParty(
            id: b.groupMemberId,
            name: b.displayName,
            amount: b.netBalance,
          ),
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final suggestions = <SuggestedSettlement>[];
    var i = 0;
    var j = 0;
    while (i < debtors.length && j < creditors.length) {
      final pay = debtors[i].amount < creditors[j].amount
          ? debtors[i].amount
          : creditors[j].amount;
      if (pay > 0.01) {
        suggestions.add(
          SuggestedSettlement(
            fromMemberId: debtors[i].id,
            fromName: debtors[i].name,
            toMemberId: creditors[j].id,
            toName: creditors[j].name,
            amount: double.parse(pay.toStringAsFixed(2)),
          ),
        );
      }
      debtors[i].amount -= pay;
      creditors[j].amount -= pay;
      if (debtors[i].amount <= 0.01) i++;
      if (creditors[j].amount <= 0.01) j++;
    }
    return suggestions;
  }
}

class _SettlementParty {
  _SettlementParty({
    required this.id,
    required this.name,
    required this.amount,
  });

  final String id;
  final String name;
  double amount;
}
