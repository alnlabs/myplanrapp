import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/home/data/setup_checklist_provider.dart';
import 'package:myplanr/features/home/presentation/setup_checklist_card.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('SetupChecklistCard widget', () {
    testWidgets('renders incomplete checklist items', (tester) async {
      const checklist = SetupChecklist(
        pantryCount: 1,
        hasFamilyMember: false,
        hasPlan: false,
        hasExpense: false,
      );

      await pumpTestApp(
        tester,
        child: const Scaffold(
          body: SetupChecklistCard(checklist: checklist),
        ),
      );

      expect(find.text(AppStrings.setupChecklistTitle), findsOneWidget);
      expect(find.text(AppStrings.setupChecklistHint), findsOneWidget);
      expect(find.text(AppStrings.checklistPantry), findsOneWidget);
      expect(find.text(AppStrings.checklistFamily), findsOneWidget);
      expect(find.text(AppStrings.checklistPlan), findsOneWidget);
      expect(find.text(AppStrings.checklistExpense), findsOneWidget);
      expect(find.text(AppStrings.optional), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(4));
    });

    testWidgets('shows completed items without chevrons', (tester) async {
      const checklist = SetupChecklist(
        pantryCount: 5,
        hasFamilyMember: true,
        hasPlan: true,
        hasExpense: true,
      );

      await pumpTestApp(
        tester,
        child: const Scaffold(
          body: SetupChecklistCard(checklist: checklist),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsNWidgets(4));
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });
  });
}
