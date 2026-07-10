import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/inventory/presentation/inventory_screen.dart';
import 'package:myplanr/features/inventory/presentation/pantry_list_tab.dart';
import 'package:myplanr/features/pantry/data/pantry_items_list_provider.dart';
import 'package:myplanr/features/pantry/data/pantry_repository.dart';
import 'package:myplanr/features/assets/data/asset_repository.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/stub_notifiers.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('InventoryScreen widget', () {
    testWidgets('renders food segment by default', (tester) async {
      await pumpShellTestApp(
        tester,
        overrides: [
          pantryItemsListProvider.overrideWith(
            () => StubPantryItemsListNotifier(items: [testPantryItem]),
          ),
          pantryItemCountProvider.overrideWith((ref) async => 1),
          lowStockItemsProvider.overrideWith((ref) async => []),
          homeAssetsProvider.overrideWith((ref) async => []),
          warrantyExpiringAssetsProvider.overrideWith((ref) async => []),
        ],
        child: const InventoryScreen(),
      );

      expect(find.text(AppStrings.inventoryTitle), findsOneWidget);
      expect(find.text('Rice'), findsOneWidget);
    });
  });

  group('PantryListTab widget', () {
    testWidgets('renders pantry items', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          pantryItemsListProvider.overrideWith(
            () => StubPantryItemsListNotifier(items: [testPantryItem]),
          ),
        ],
        child: const Scaffold(body: PantryListTab(query: '')),
      );

      expect(find.text('Rice'), findsOneWidget);
    });
  });
}
