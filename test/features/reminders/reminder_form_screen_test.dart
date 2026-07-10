import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/reminders/presentation/reminder_form_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('ReminderFormScreen widget', () {
    testWidgets('requires reminder title', (tester) async {
      await pumpTestApp(
        tester,
        child: const ReminderFormScreen(),
      );

      await tapSave(tester);
      expect(find.text(AppStrings.requiredField), findsOneWidget);
    });

    testWidgets('requires reminder date/time when reminder is enabled',
        (tester) async {
      await pumpTestApp(
        tester,
        child: const ReminderFormScreen(),
      );

      await tester.enterText(find.byType(TextFormField).first, 'Call plumber');
      await tester.pumpAndSettle();
      await tapSave(tester);

      expect(find.text(AppStrings.pickReminderDateTime), findsOneWidget);
    });

    testWidgets('notes field is optional', (tester) async {
      await pumpTestApp(
        tester,
        child: const ReminderFormScreen(),
      );

      await tester.enterText(find.byType(TextFormField).at(1), 'Urgent fix');
      await tester.pumpAndSettle();

      expect(find.text('Urgent fix'), findsOneWidget);
    });

    testWidgets('can disable reminder toggle', (tester) async {
      await pumpTestApp(
        tester,
        child: const ReminderFormScreen(),
      );

      final reminderSwitch = find.byType(SwitchListTile);
      expect(reminderSwitch, findsOneWidget);

      await tester.tap(reminderSwitch);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.reminderAt), findsNothing);
    });
  });
}
