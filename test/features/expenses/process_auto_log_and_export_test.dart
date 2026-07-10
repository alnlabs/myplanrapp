import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/expenses/data/expenses_list_provider.dart';
import 'package:myplanr/features/expenses/data/recurring_money_rule_repository.dart';
import 'package:myplanr/features/expenses/utils/money_report_export.dart';

import 'package:myplanr/features/auth/data/auth_repository.dart';
import '../../helpers/provider_overrides.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/stub_repositories.dart';

void main() {
  group('processAutoLogRecurringExpenses', () {
    testWidgets('returns logged count from repository', (tester) async {
      int? result;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...testAuthOverrides,
            recurringMoneyRuleRepositoryProvider.overrideWith(
              (ref) => StubRecurringMoneyRuleRepository(autoLogCount: 2),
            ),
          ],
          child: MaterialApp(
            home: _Harness(onResult: (count) => result = count),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, 2);
    });

    testWidgets('returns zero when household missing', (tester) async {
      int? result;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider.overrideWith((ref) async => null),
            recurringMoneyRuleRepositoryProvider.overrideWith(
              (ref) => StubRecurringMoneyRuleRepository(autoLogCount: 5),
            ),
          ],
          child: MaterialApp(
            home: _Harness(onResult: (count) => result = count),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, 0);
    });
  });

  group('showMoneyReportExportSheet', () {
    testWidgets('shows copy and share actions', (tester) async {
      await pumpTestApp(
        tester,
        child: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showMoneyReportExportSheet(
                context,
                csv: 'date,amount\n2026-07-01,100',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.exportReport), findsOneWidget);
      expect(find.text(AppStrings.copyReport), findsOneWidget);
      expect(find.text(AppStrings.shareReport), findsOneWidget);
    });
  });
}

class _Harness extends ConsumerStatefulWidget {
  const _Harness({required this.onResult});

  final void Function(int count) onResult;

  @override
  ConsumerState<_Harness> createState() => _HarnessState();
}

class _HarnessState extends ConsumerState<_Harness> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final count = await processAutoLogRecurringExpenses(ref);
      widget.onResult(count);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
