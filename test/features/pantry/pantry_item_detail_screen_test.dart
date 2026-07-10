import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/pantry/data/pantry_repository.dart';
import 'package:myplanr/features/pantry/presentation/pantry_item_detail_screen.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('PantryItemDetailScreen widget', () {
    testWidgets('renders item details, actions, and stock history', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          pantryItemProvider(testPantryItem.id)
              .overrideWith((ref) async => testPantryItem),
          stockEventsProvider(testPantryItem.id)
              .overrideWith((ref) async => [testStockEvent]),
        ],
        child: PantryItemDetailScreen(item: testPantryItem),
      );

      expect(find.text('Rice'), findsOneWidget);
      expect(find.textContaining('2'), findsWidgets);
      expect(find.text(AppStrings.useItem), findsOneWidget);
      expect(find.text(AppStrings.restockItem), findsOneWidget);
      expect(find.text(AppStrings.stockHistory), findsOneWidget);
      expect(find.textContaining('Weekly shop'), findsOneWidget);
    });

    testWidgets('shows empty stock history message', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          pantryItemProvider(testPantryItem.id)
              .overrideWith((ref) async => testPantryItem),
          stockEventsProvider(testPantryItem.id)
              .overrideWith((ref) async => []),
        ],
        child: PantryItemDetailScreen(item: testPantryItem),
      );

      expect(find.text(AppStrings.emptyStockHistory), findsOneWidget);
    });
  });
}
