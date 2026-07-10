import '../../../shared/models/expense_group.dart';
import '../../../shared/models/expense_split.dart';
import 'expense_split_calculator.dart';

/// Pure split-building logic extracted from [ExpenseGroupFieldsState].
class ExpenseGroupSplitBuilder {
  ExpenseGroupSplitBuilder._();

  static List<ExpenseSplitInput>? build({
    required String? groupId,
    required ExpenseGroup? group,
    required Set<String> participants,
    required ExpenseShareType shareType,
    required String? paidByMemberId,
    required double amount,
    required Map<String, String> exactTextsByMemberId,
    required Map<String, String> percentTextsByMemberId,
  }) {
    if (groupId == null) return const [];
    if (group == null || !group.isShared) return const [];
    if (participants.length < 2) return null;

    switch (shareType) {
      case ExpenseShareType.equal:
        return ExpenseSplitCalculator.splitEqually(
          amount: amount,
          participantIds: participants.toList(),
          payerMemberId: paidByMemberId ?? '',
        );
      case ExpenseShareType.exact:
        final map = <String, double>{};
        for (final id in participants) {
          final text = exactTextsByMemberId[id]?.trim() ?? '';
          if (text.isEmpty) return null;
          map[id] = double.parse(text);
        }
        final splits = ExpenseSplitCalculator.splitByExact(amountsByMember: map);
        return ExpenseSplitCalculator.sumsToAmount(splits, amount) ? splits : null;
      case ExpenseShareType.percent:
        final map = <String, double>{};
        for (final id in participants) {
          final text = percentTextsByMemberId[id]?.trim() ?? '';
          if (text.isEmpty) return null;
          map[id] = double.parse(text);
        }
        if (map.values.fold<double>(0, (a, b) => a + b).round() != 100) {
          return null;
        }
        return ExpenseSplitCalculator.splitByPercent(
          amount: amount,
          percentsByMember: map,
        );
    }
  }
}
