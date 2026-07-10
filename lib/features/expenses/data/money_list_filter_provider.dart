import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/expense.dart';

enum MoneyListFilter {
  all,
  expenses,
  income,
}

class MoneyListFilterState {
  const MoneyListFilterState({
    this.typeFilter = MoneyListFilter.all,
    this.familyMemberId,
    this.groupId,
  });

  final MoneyListFilter typeFilter;
  final String? familyMemberId;
  final String? groupId;

  MoneyEntryType? get entryType {
    return switch (typeFilter) {
      MoneyListFilter.expenses => MoneyEntryType.expense,
      MoneyListFilter.income => MoneyEntryType.income,
      MoneyListFilter.all => null,
    };
  }

  MoneyListFilterState copyWith({
    MoneyListFilter? typeFilter,
    String? familyMemberId,
    String? groupId,
    bool clearMember = false,
    bool clearGroup = false,
  }) {
    return MoneyListFilterState(
      typeFilter: typeFilter ?? this.typeFilter,
      familyMemberId:
          clearMember ? null : (familyMemberId ?? this.familyMemberId),
      groupId: clearGroup ? null : (groupId ?? this.groupId),
    );
  }
}

class MoneyListFilterNotifier extends Notifier<MoneyListFilterState> {
  @override
  MoneyListFilterState build() => const MoneyListFilterState();

  void setTypeFilter(MoneyListFilter filter) {
    state = state.copyWith(
      typeFilter: filter,
      clearMember: filter != MoneyListFilter.income,
    );
  }

  void setFamilyMemberId(String? memberId) {
    state = state.copyWith(familyMemberId: memberId);
  }

  void setGroupId(String? groupId) {
    state = state.copyWith(groupId: groupId);
  }
}

final moneyListFilterProvider =
    NotifierProvider<MoneyListFilterNotifier, MoneyListFilterState>(
  MoneyListFilterNotifier.new,
);
