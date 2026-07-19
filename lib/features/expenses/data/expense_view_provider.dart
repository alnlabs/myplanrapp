import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/expense.dart';

enum ExpenseViewKind { all, personal, household, groups, group }

/// The top-level view selector for the Expenses screen. Orthogonal to the
/// money-type/member filter and the period filter. Resolves to a
/// `(MoneyScope?, groupId)` pair used across list, summary and recurring
/// providers.
class ExpenseView {
  const ExpenseView._(this.kind, this.groupId);

  const ExpenseView.all() : this._(ExpenseViewKind.all, null);
  const ExpenseView.personal() : this._(ExpenseViewKind.personal, null);
  const ExpenseView.household() : this._(ExpenseViewKind.household, null);

  /// The "Groups" tab hub (no specific group picked yet).
  const ExpenseView.groups() : this._(ExpenseViewKind.groups, null);
  const ExpenseView.group(String groupId)
      : this._(ExpenseViewKind.group, groupId);

  final ExpenseViewKind kind;
  final String? groupId;

  bool get isGroup => kind == ExpenseViewKind.group;

  /// True when the Groups tab is active (hub or a specific group).
  bool get isGroupsTab =>
      kind == ExpenseViewKind.groups || kind == ExpenseViewKind.group;

  /// The scope filter to apply. `null` means "all rows visible to me"
  /// (household rows plus my own personal rows), which RLS already enforces.
  MoneyScope? get scope {
    return switch (kind) {
      ExpenseViewKind.personal => MoneyScope.personal,
      ExpenseViewKind.household => MoneyScope.household,
      // Group items are always stored as household scope.
      ExpenseViewKind.group => MoneyScope.household,
      ExpenseViewKind.groups => MoneyScope.household,
      ExpenseViewKind.all => null,
    };
  }

  /// The group id to filter by, only when a specific group is selected.
  String? get groupFilterId => isGroup ? groupId : null;

  @override
  bool operator ==(Object other) =>
      other is ExpenseView &&
      other.kind == kind &&
      other.groupId == groupId;

  @override
  int get hashCode => Object.hash(kind, groupId);
}

class ExpenseViewNotifier extends Notifier<ExpenseView> {
  @override
  ExpenseView build() => const ExpenseView.all();

  void setView(ExpenseView view) => state = view;
}

final expenseViewProvider =
    NotifierProvider<ExpenseViewNotifier, ExpenseView>(
  ExpenseViewNotifier.new,
);
