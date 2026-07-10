import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/expenses/data/expense_date_filter.dart';
import 'package:myplanr/features/expenses/data/expense_date_filter_provider.dart';
import 'package:myplanr/features/expenses/data/expenses_list_provider.dart';
import 'package:myplanr/features/expenses/presentation/expense_period_filter_bar.dart';
import 'package:myplanr/shared/models/expense.dart';
import 'package:myplanr/shared/models/paginated_result.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('ExpensePeriodFilterBar widget', () {
    testWidgets('renders all period chips and label', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          expensesListProvider.overrideWith(_StubExpensesListNotifier.new),
        ],
        child: const Scaffold(body: ExpensePeriodFilterBar()),
      );

      expect(find.text(AppStrings.periodToday), findsOneWidget);
      expect(find.text(AppStrings.periodThisWeek), findsOneWidget);
      expect(find.text(AppStrings.periodThisMonth), findsNWidgets(2));
      expect(find.text(AppStrings.periodCustomRange), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNWidgets(4));
    });

    testWidgets('updates filter when month chip is tapped', (tester) async {
      late ExpenseDateFilter captured;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseDateFilterProvider.overrideWith(() {
              return _CapturingFilterNotifier((f) => captured = f);
            }),
            expensesListProvider.overrideWith(_StubExpensesListNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ExpensePeriodFilterBar()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(ChoiceChip, AppStrings.periodThisMonth),
      );
      await tester.pumpAndSettle();

      expect(captured.preset, ExpenseDatePreset.month);
    });

    testWidgets('golden — default month filter bar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expensesListProvider.overrideWith(_StubExpensesListNotifier.new),
          ],
          child: MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: ExpensePeriodFilterBar(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ExpensePeriodFilterBar),
        matchesGoldenFile('goldens/expense_period_filter_bar.png'),
      );
    });
  });
}

class _CapturingFilterNotifier extends ExpenseDateFilterNotifier {
  _CapturingFilterNotifier(this._onChange);

  final void Function(ExpenseDateFilter filter) _onChange;

  @override
  ExpenseDateFilter build() => const ExpenseDateFilter();

  @override
  void setPreset(ExpenseDatePreset preset) {
    super.setPreset(preset);
    _onChange(state);
  }
}

class _StubExpensesListNotifier extends ExpensesListNotifier {
  @override
  Future<String?> get householdId async => null;

  @override
  Future<PaginatedResult<Expense>> fetchPage(
    String householdId,
    int offset,
    int limit,
  ) async {
    return const PaginatedResult(items: [], hasMore: false);
  }
}
