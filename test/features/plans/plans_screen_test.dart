import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/plans/data/plans_list_provider.dart';
import 'package:myplanr/features/plans/data/todo_reminders_filter.dart';
import 'package:myplanr/features/plans/presentation/plans_screen.dart';
import 'package:myplanr/features/reminders/data/reminder_repository.dart';
import '../../helpers/provider_overrides.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/stub_notifiers.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('PlansScreen widget', () {
    testWidgets('renders plans list with filter bar', (tester) async {
      await pumpShellTestApp(
        tester,
        overrides: [
          ...testAuthOverrides,
          plansListProvider.overrideWith(_StubPlansListNotifier.new),
          appRemindersProvider.overrideWith((ref) async => []),
        ],
        child: const PlansScreen(),
      );

      expect(find.text(AppStrings.plansTitle), findsOneWidget);
      expect(find.text('Buy groceries'), findsOneWidget);
      expect(find.text(AppStrings.tabAllPlans), findsOneWidget);
      expect(find.text(AppStrings.addPlan), findsOneWidget);
    });

    testWidgets('opens add menu from FAB', (tester) async {
      await pumpShellTestApp(
        tester,
        overrides: [
          ...testAuthOverrides,
          plansListProvider.overrideWith(_StubPlansListNotifier.new),
          appRemindersProvider.overrideWith((ref) async => []),
        ],
        child: const PlansScreen(),
      );

      await tester.tap(find.widgetWithText(FloatingActionButton, AppStrings.addPlan));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.addReminder), findsOneWidget);
    });

    testWidgets('switches to reminders-only filter', (tester) async {
      await pumpShellTestApp(
        tester,
        overrides: [
          ...testAuthOverrides,
          plansListProvider.overrideWith(_StubPlansListNotifier.new),
          appRemindersProvider.overrideWith((ref) async => []),
        ],
        child: const PlansScreen(),
      );

      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.filterReminders).last);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.filterReminders), findsWidgets);
      expect(find.text('Buy groceries'), findsNothing);
    });
  });
}

class _StubPlansListNotifier extends StubPlansListNotifier {
  _StubPlansListNotifier() : super(items: [testPlan]);
}
