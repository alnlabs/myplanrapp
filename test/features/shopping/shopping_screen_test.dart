import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/shopping/data/shopping_list_provider.dart';
import 'package:myplanr/features/shopping/data/shopping_repository.dart';
import 'package:myplanr/features/shopping/presentation/shopping_screen.dart';
import 'package:myplanr/shared/models/shopping_list_item.dart';

import '../../helpers/provider_overrides.dart';
import '../../helpers/provider_overrides.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('ShoppingScreen widget', () {
    testWidgets('renders shopping list items', (tester) async {
      await pumpShellTestApp(
        tester,
        overrides: [
          ...testAuthOverrides,
          shoppingListProvider.overrideWith(
            (ref) async => [testShoppingListItem],
          ),
          shoppingRepositoryProvider.overrideWith((ref) => _StubShoppingRepository()),
        ],
        child: const ShoppingScreen(),
      );

      expect(find.text(AppStrings.shopTitle), findsOneWidget);
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text(AppStrings.restockOnBuy), findsOneWidget);
      expect(find.text(AppStrings.addToShop), findsOneWidget);
    });

    testWidgets('shows empty state when list is empty', (tester) async {
      await pumpShellTestApp(
        tester,
        overrides: [
          ...testAuthOverrides,
          shoppingListProvider.overrideWith((ref) async => []),
          shoppingRepositoryProvider.overrideWith((ref) => _StubShoppingRepository()),
        ],
        child: const ShoppingScreen(),
      );

      expect(find.text(AppStrings.emptyShop), findsOneWidget);
      expect(find.text(AppStrings.emptyShopHint), findsOneWidget);
    });
  });
}

class _StubShoppingRepository implements ShoppingRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #syncLowStockToShop) {
      return Future<void>.value();
    }
    if (invocation.memberName == #fetchItems) {
      return Future<List<ShoppingListItem>>.value([]);
    }
    return super.noSuchMethod(invocation);
  }
}
