import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/pantry/data/pantry_repository.dart';
import 'package:myplanr/features/pantry/presentation/pantry_item_detail_screen.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('PantryItemDetailScreen widget', () {
    testWidgets('renders item details and stock actions', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          pantryItemProvider(testPantryItem.id)
              .overrideWith((ref) async => testPantryItem),
        ],
        child: PantryItemDetailScreen(item: testPantryItem),
      );

      expect(find.text('Rice'), findsOneWidget);
      expect(find.textContaining('2'), findsWidgets);
      expect(find.text(AppStrings.useItem), findsOneWidget);
      expect(find.text(AppStrings.restockItem), findsOneWidget);
    });

    testWidgets('no longer shows a stock history section', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          pantryItemProvider(testPantryItem.id)
              .overrideWith((ref) async => testPantryItem),
        ],
        child: PantryItemDetailScreen(item: testPantryItem),
      );

      expect(find.text(AppStrings.stockHistory), findsNothing);
    });
  });
}
