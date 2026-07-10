import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/household/data/family_repository.dart';
import 'package:myplanr/features/plans/presentation/plan_form_screen.dart';
import 'package:myplanr/shared/constants/meal_slots.dart';
import 'package:myplanr/shared/constants/plan_constants.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  final overrides = [
    familyRosterProvider.overrideWith((ref) async => testFamilyMembers),
  ];

  group('PlanFormScreen widget', () {
    testWidgets('requires plan title', (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides,
        child: const PlanFormScreen(),
      );

      await tapSave(tester);
      expect(find.text(AppStrings.requiredField), findsOneWidget);
    });

    testWidgets('reminder is off by default for new plans', (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides,
        child: const PlanFormScreen(),
      );

      final reminderSwitch = find.widgetWithText(SwitchListTile, AppStrings.reminder);
      expect(tester.widget<SwitchListTile>(reminderSwitch).value, isFalse);
    });

    testWidgets('shows meal slot chips for meal plan type', (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides,
        child: const PlanFormScreen(initialPlanType: PlanTypes.meal),
      );

      expect(find.text(MealSlots.labelFor(MealSlots.breakfast)), findsOneWidget);
      expect(find.text(MealSlots.labelFor(MealSlots.lunch)), findsOneWidget);
      expect(find.text(MealSlots.labelFor(MealSlots.dinner)), findsOneWidget);
    });

    testWidgets('description field is optional', (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides,
        child: const PlanFormScreen(),
      );

      await tester.enterText(find.byType(TextFormField).at(1), 'Extra details');
      await tester.pumpAndSettle();

      expect(find.text('Extra details'), findsOneWidget);
    });

    testWidgets('renders roster member dropdowns', (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides,
        child: const PlanFormScreen(),
      );

      expect(find.text(AppStrings.forMember), findsOneWidget);
      expect(find.text(AppStrings.assignedTo), findsOneWidget);

      await tester.tap(find.text(AppStrings.forMember));
      await tester.pumpAndSettle();
      expect(find.text('Alex Parent'), findsOneWidget);
    });
  });
}
