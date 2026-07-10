import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/features/expenses/utils/expense_group_split_builder.dart';
import 'package:myplanr/features/expenses/utils/expense_split_calculator.dart';
import 'package:myplanr/shared/models/expense_group.dart';
import 'package:myplanr/shared/models/expense_split.dart';

void main() {
  const sharedGroup = ExpenseGroup(
    id: 'g1',
    householdId: 'hh1',
    name: 'Trip',
    groupType: 'shared',
  );

  const personalGroup = ExpenseGroup(
    id: 'g2',
    householdId: 'hh1',
    name: 'Personal',
    groupType: 'personal',
  );

  group('ExpenseGroupSplitBuilder.build', () {
    test('returns empty list when groupId is null', () {
      expect(
        ExpenseGroupSplitBuilder.build(
          groupId: null,
          group: sharedGroup,
          participants: {'a', 'b'},
          shareType: ExpenseShareType.equal,
          paidByMemberId: 'a',
          amount: 100,
          exactTextsByMemberId: const {},
          percentTextsByMemberId: const {},
        ),
        isEmpty,
      );
    });

    test('returns empty list for non-shared group', () {
      expect(
        ExpenseGroupSplitBuilder.build(
          groupId: 'g2',
          group: personalGroup,
          participants: {'a', 'b'},
          shareType: ExpenseShareType.equal,
          paidByMemberId: 'a',
          amount: 100,
          exactTextsByMemberId: const {},
          percentTextsByMemberId: const {},
        ),
        isEmpty,
      );
    });

    test('returns null when fewer than two participants', () {
      expect(
        ExpenseGroupSplitBuilder.build(
          groupId: 'g1',
          group: sharedGroup,
          participants: {'a'},
          shareType: ExpenseShareType.equal,
          paidByMemberId: 'a',
          amount: 100,
          exactTextsByMemberId: const {},
          percentTextsByMemberId: const {},
        ),
        isNull,
      );
    });

    test('splits equally between participants', () {
      final splits = ExpenseGroupSplitBuilder.build(
        groupId: 'g1',
        group: sharedGroup,
        participants: {'a', 'b'},
        shareType: ExpenseShareType.equal,
        paidByMemberId: 'a',
        amount: 100,
        exactTextsByMemberId: const {},
        percentTextsByMemberId: const {},
      );
      expect(splits, hasLength(2));
      final total = splits!.fold<double>(0, (sum, s) => sum + s.owedAmount);
      expect(total, closeTo(100, 0.001));
    });

    test('splits by exact amounts when they sum to total', () {
      final splits = ExpenseGroupSplitBuilder.build(
        groupId: 'g1',
        group: sharedGroup,
        participants: {'a', 'b'},
        shareType: ExpenseShareType.exact,
        paidByMemberId: 'a',
        amount: 100,
        exactTextsByMemberId: const {'a': '60', 'b': '40'},
        percentTextsByMemberId: const {},
      );
      expect(splits, hasLength(2));
      final byId = {for (final s in splits!) s.groupMemberId: s.owedAmount};
      expect(byId['a'], 60);
      expect(byId['b'], 40);
    });

    test('returns null when exact amounts do not sum to total', () {
      expect(
        ExpenseGroupSplitBuilder.build(
          groupId: 'g1',
          group: sharedGroup,
          participants: {'a', 'b'},
          shareType: ExpenseShareType.exact,
          paidByMemberId: 'a',
          amount: 100,
          exactTextsByMemberId: const {'a': '60', 'b': '30'},
          percentTextsByMemberId: const {},
        ),
        isNull,
      );
    });

    test('returns null when exact field is empty', () {
      expect(
        ExpenseGroupSplitBuilder.build(
          groupId: 'g1',
          group: sharedGroup,
          participants: {'a', 'b'},
          shareType: ExpenseShareType.exact,
          paidByMemberId: 'a',
          amount: 100,
          exactTextsByMemberId: const {'a': '60', 'b': ''},
          percentTextsByMemberId: const {},
        ),
        isNull,
      );
    });

    test('splits by percent when total is 100', () {
      final splits = ExpenseGroupSplitBuilder.build(
        groupId: 'g1',
        group: sharedGroup,
        participants: {'a', 'b'},
        shareType: ExpenseShareType.percent,
        paidByMemberId: 'a',
        amount: 200,
        exactTextsByMemberId: const {},
        percentTextsByMemberId: const {'a': '75', 'b': '25'},
      );
      expect(splits, hasLength(2));
      final byId = {for (final s in splits!) s.groupMemberId: s.owedAmount};
      expect(byId['a'], 150);
      expect(byId['b'], 50);
    });

    test('returns null when percents do not total 100', () {
      expect(
        ExpenseGroupSplitBuilder.build(
          groupId: 'g1',
          group: sharedGroup,
          participants: {'a', 'b'},
          shareType: ExpenseShareType.percent,
          paidByMemberId: 'a',
          amount: 200,
          exactTextsByMemberId: const {},
          percentTextsByMemberId: const {'a': '70', 'b': '25'},
        ),
        isNull,
      );
    });

    test('returns null when percent field is empty', () {
      expect(
        ExpenseGroupSplitBuilder.build(
          groupId: 'g1',
          group: sharedGroup,
          participants: {'a', 'b'},
          shareType: ExpenseShareType.percent,
          paidByMemberId: 'a',
          amount: 200,
          exactTextsByMemberId: const {},
          percentTextsByMemberId: const {'a': '50', 'b': ''},
        ),
        isNull,
      );
    });
  });
}
