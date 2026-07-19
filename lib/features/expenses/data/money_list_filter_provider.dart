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
  });

  final MoneyListFilter typeFilter;
  final String? familyMemberId;

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
    bool clearMember = false,
  }) {
    return MoneyListFilterState(
      typeFilter: typeFilter ?? this.typeFilter,
      familyMemberId:
          clearMember ? null : (familyMemberId ?? this.familyMemberId),
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
}

final moneyListFilterProvider =
    NotifierProvider<MoneyListFilterNotifier, MoneyListFilterState>(
  MoneyListFilterNotifier.new,
);
