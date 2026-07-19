import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/pantry/presentation/pantry_screen.dart';
import 'package:myplanr/shared/constants/pantry_availability.dart';
import 'package:myplanr/shared/models/pantry_item.dart';
import 'package:myplanr/shared/widgets/loading_button.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('showStockSheet widget', () {
    testWidgets('opens use-item sheet with stepper control', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showStockSheet(
                    context,
                    ref,
                    item: testPantryItem,
                    isRestock: false,
                  ),
                  child: const Text('Open use sheet'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open use sheet'));
      await tester.pumpAndSettle();

      // No typed field / required validation anymore — an easy tap control with
      // a slider and a "Use all" shortcut is shown instead.
      expect(find.text(AppStrings.useItem), findsOneWidget);
      expect(find.textContaining(AppStrings.available), findsOneWidget);
      expect(find.textContaining(AppStrings.remaining), findsOneWidget);
      expect(find.text(AppStrings.useAll), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.byType(LoadingButton), findsOneWidget);
    });

    testWidgets('shows clear-availability toggle on restock', (tester) async {
      final item = PantryItem(
        id: 'pantry-2',
        householdId: testHouseholdId,
        name: 'Milk',
        quantity: 1,
        unit: 'L',
        availabilityStatus: PantryAvailability.warning,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showStockSheet(
                    context,
                    ref,
                    item: item,
                    isRestock: true,
                  ),
                  child: const Text('Open restock sheet'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open restock sheet'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.restockItem), findsOneWidget);
      expect(find.text(AppStrings.clearAvailabilityOnRestock), findsOneWidget);
    });
  });
}
