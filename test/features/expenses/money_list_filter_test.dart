import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/features/expenses/data/money_list_filter_provider.dart';
import 'package:myplanr/shared/models/expense.dart';

void main() {
  group('MoneyListFilterState defaults', () {
    test('starts with all types and no member or group', () {
      const state = MoneyListFilterState();
      expect(state.typeFilter, MoneyListFilter.all);
      expect(state.familyMemberId, isNull);
      expect(state.groupId, isNull);
      expect(state.entryType, isNull);
    });
  });

  group('MoneyListFilterState.entryType', () {
    test('maps expenses filter', () {
      const state = MoneyListFilterState(typeFilter: MoneyListFilter.expenses);
      expect(state.entryType, MoneyEntryType.expense);
    });

    test('maps income filter', () {
      const state = MoneyListFilterState(typeFilter: MoneyListFilter.income);
      expect(state.entryType, MoneyEntryType.income);
    });

    test('maps all filter to null', () {
      const state = MoneyListFilterState(typeFilter: MoneyListFilter.all);
      expect(state.entryType, isNull);
    });
  });

  group('MoneyListFilterState.copyWith', () {
    const base = MoneyListFilterState(
      typeFilter: MoneyListFilter.income,
      familyMemberId: 'member-1',
      groupId: 'group-1',
    );

    test('updates type filter', () {
      final updated = base.copyWith(typeFilter: MoneyListFilter.expenses);
      expect(updated.typeFilter, MoneyListFilter.expenses);
      expect(updated.familyMemberId, 'member-1');
      expect(updated.groupId, 'group-1');
    });

    test('updates family member id', () {
      final updated = base.copyWith(familyMemberId: 'member-2');
      expect(updated.familyMemberId, 'member-2');
    });

    test('updates group id', () {
      final updated = base.copyWith(groupId: 'group-2');
      expect(updated.groupId, 'group-2');
    });

    test('clearMember forces null member', () {
      final updated = base.copyWith(clearMember: true);
      expect(updated.familyMemberId, isNull);
      expect(updated.groupId, 'group-1');
    });

    test('clearGroup forces null group', () {
      final updated = base.copyWith(clearGroup: true);
      expect(updated.groupId, isNull);
      expect(updated.familyMemberId, 'member-1');
    });
  });

  group('MoneyListFilterNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('setTypeFilter updates filter', () {
      container.read(moneyListFilterProvider.notifier).setTypeFilter(
            MoneyListFilter.expenses,
          );
      expect(
        container.read(moneyListFilterProvider).typeFilter,
        MoneyListFilter.expenses,
      );
    });

    test('setTypeFilter clears member when not income', () {
      final notifier = container.read(moneyListFilterProvider.notifier);
      notifier.setFamilyMemberId('member-1');
      notifier.setTypeFilter(MoneyListFilter.expenses);
      expect(container.read(moneyListFilterProvider).familyMemberId, isNull);
    });

    test('setTypeFilter keeps member when income', () {
      final notifier = container.read(moneyListFilterProvider.notifier);
      notifier.setFamilyMemberId('member-1');
      notifier.setTypeFilter(MoneyListFilter.income);
      expect(
        container.read(moneyListFilterProvider).familyMemberId,
        'member-1',
      );
    });

    test('setTypeFilter clears member when switching to all', () {
      final notifier = container.read(moneyListFilterProvider.notifier);
      notifier.setFamilyMemberId('member-1');
      notifier.setTypeFilter(MoneyListFilter.all);
      expect(container.read(moneyListFilterProvider).familyMemberId, isNull);
    });

    test('setFamilyMemberId updates member', () {
      container
          .read(moneyListFilterProvider.notifier)
          .setFamilyMemberId('member-9');
      expect(
        container.read(moneyListFilterProvider).familyMemberId,
        'member-9',
      );
    });

    test('setGroupId updates group', () {
      container.read(moneyListFilterProvider.notifier).setGroupId('group-9');
      expect(container.read(moneyListFilterProvider).groupId, 'group-9');
    });
  });
}
