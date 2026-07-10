import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/subscriptions/presentation/subscription_form_screen.dart';
import 'package:myplanr/shared/constants/subscription_constants.dart';

import '../../helpers/provider_overrides.dart';
import '../../helpers/pump_app.dart';

void main() {
  group('SubscriptionFormScreen widget', () {
    testWidgets('requires subscription name', (tester) async {
      await pumpTestApp(
        tester,
        overrides: testAuthOverrides,
        child: const SubscriptionFormScreen(),
      );

      await tapSave(tester);
      expect(find.text(AppStrings.requiredField), findsOneWidget);
    });

    testWidgets('amount field is optional', (tester) async {
      await pumpTestApp(
        tester,
        overrides: testAuthOverrides,
        child: const SubscriptionFormScreen(),
      );

      await tester.enterText(find.byType(TextFormField).first, 'Spotify');
      await tester.enterText(find.byType(TextFormField).at(1), 'not-a-number');
      await tester.pumpAndSettle();
      await tapSave(tester);

      expect(find.text(AppStrings.invalidAmount), findsNothing);
      expect(find.text(AppStrings.requiredField), findsNothing);
    });

    testWidgets('reminder is off by default for new subscriptions', (tester) async {
      await pumpTestApp(
        tester,
        overrides: testAuthOverrides,
        child: const SubscriptionFormScreen(),
      );

      final reminderSwitch = find.widgetWithText(SwitchListTile, AppStrings.reminder);
      expect(tester.widget<SwitchListTile>(reminderSwitch).value, isFalse);
    });

    testWidgets('renders billing cycle and due day fields', (tester) async {
      await pumpTestApp(
        tester,
        overrides: testAuthOverrides,
        child: const SubscriptionFormScreen(),
      );

      expect(find.text(AppStrings.billingCycle), findsOneWidget);
      expect(find.text(AppStrings.dueDay), findsOneWidget);
      expect(find.text(BillingCycles.labelFor(BillingCycles.monthly)), findsOneWidget);
    });

    testWidgets('shows yearly due month when billing cycle is yearly',
        (tester) async {
      await pumpTestApp(
        tester,
        overrides: testAuthOverrides,
        child: const SubscriptionFormScreen(),
      );

      await tester.tap(find.text(AppStrings.billingCycle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(BillingCycles.labelFor(BillingCycles.yearly)).last);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.dueMonth), findsOneWidget);
    });

    testWidgets('notes field accepts optional text', (tester) async {
      await pumpTestApp(
        tester,
        overrides: testAuthOverrides,
        child: const SubscriptionFormScreen(),
      );

      final notesField = find.byType(TextFormField).last;
      await tester.ensureVisible(notesField);
      await tester.enterText(notesField, 'Family plan');
      await tester.pumpAndSettle();

      expect(find.text('Family plan'), findsOneWidget);
    });
  });
}
