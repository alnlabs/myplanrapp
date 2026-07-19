import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/features/expenses/data/expense_view_provider.dart';
import 'package:myplanr/shared/models/expense.dart';

void main() {
  group('ExpenseView scope/group resolution', () {
    test('all view applies no scope and no group filter', () {
      const view = ExpenseView.all();
      expect(view.kind, ExpenseViewKind.all);
      expect(view.scope, isNull);
      expect(view.groupFilterId, isNull);
      expect(view.isGroup, isFalse);
    });

    test('personal view resolves to personal scope', () {
      const view = ExpenseView.personal();
      expect(view.scope, MoneyScope.personal);
      expect(view.groupFilterId, isNull);
    });

    test('household view resolves to household scope', () {
      const view = ExpenseView.household();
      expect(view.scope, MoneyScope.household);
      expect(view.groupFilterId, isNull);
    });

    test('group view resolves to household scope and group filter', () {
      const view = ExpenseView.group('group-7');
      expect(view.isGroup, isTrue);
      expect(view.scope, MoneyScope.household);
      expect(view.groupFilterId, 'group-7');
    });

    test('groups hub view has no specific group filter', () {
      const view = ExpenseView.groups();
      expect(view.kind, ExpenseViewKind.groups);
      expect(view.isGroup, isFalse);
      expect(view.isGroupsTab, isTrue);
      expect(view.groupFilterId, isNull);
    });

    test('specific group is also part of the Groups tab', () {
      const view = ExpenseView.group('group-7');
      expect(view.isGroupsTab, isTrue);
    });

    test('value equality by kind and group id', () {
      expect(const ExpenseView.all(), const ExpenseView.all());
      expect(const ExpenseView.group('a'), const ExpenseView.group('a'));
      expect(
        const ExpenseView.group('a') == const ExpenseView.group('b'),
        isFalse,
      );
    });
  });

  group('ExpenseViewNotifier', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('defaults to all', () {
      expect(container.read(expenseViewProvider), const ExpenseView.all());
    });

    test('setView updates state', () {
      container
          .read(expenseViewProvider.notifier)
          .setView(const ExpenseView.personal());
      expect(
        container.read(expenseViewProvider),
        const ExpenseView.personal(),
      );
    });
  });
}
