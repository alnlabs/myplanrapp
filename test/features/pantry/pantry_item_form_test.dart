import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/pantry/presentation/pantry_item_form_screen.dart';
import 'package:myplanr/shared/constants/pantry_availability.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('PantryItemFormScreen widget', () {
    testWidgets('requires item name', (tester) async {
      await pumpTestApp(
        tester,
        child: const PantryItemFormScreen(),
      );

      await tapSave(tester);
      expect(find.text(AppStrings.requiredField), findsOneWidget);
    });

    testWidgets('requires quantity when availability is not set', (tester) async {
      await pumpTestApp(
        tester,
        child: const PantryItemFormScreen(),
      );

      await tester.enterText(find.byType(TextFormField).first, 'Milk');
      await tester.pumpAndSettle();
      await tapSave(tester);

      expect(find.text(AppStrings.pantryTrackingRequired), findsOneWidget);
    });

    testWidgets('allows empty quantity when availability chip is selected',
        (tester) async {
      await pumpTestApp(
        tester,
        child: const PantryItemFormScreen(),
      );

      await tester.enterText(find.byType(TextFormField).first, 'Bread');
      await tester.tap(find.text(PantryAvailability.label(PantryAvailability.fine)));
      await tester.pumpAndSettle();
      await tapSave(tester);

      expect(find.text(AppStrings.pantryTrackingRequired), findsNothing);
    });

    testWidgets('rejects invalid quantity', (tester) async {
      await pumpTestApp(
        tester,
        child: const PantryItemFormScreen(),
      );

      await tester.enterText(find.byType(TextFormField).first, 'Sugar');
      await tester.enterText(find.byType(TextFormField).at(2), 'bad');
      await tester.pumpAndSettle();
      await tapSave(tester);

      expect(find.text(AppStrings.invalidQuantity), findsOneWidget);
    });

    testWidgets('prefills fields when editing existing item', (tester) async {
      await pumpTestApp(
        tester,
        child: PantryItemFormScreen(item: testPantryItem),
      );

      expect(find.text('Rice'), findsOneWidget);
      expect(find.text('2.0'), findsOneWidget);
      expect(find.text(AppStrings.editItem), findsOneWidget);
    });

    testWidgets('brand field is optional', (tester) async {
      await pumpTestApp(
        tester,
        child: const PantryItemFormScreen(),
      );

      await tester.enterText(find.byType(TextFormField).at(1), 'Amul');
      await tester.pumpAndSettle();

      expect(find.text('Amul'), findsOneWidget);
    });
  });
}
