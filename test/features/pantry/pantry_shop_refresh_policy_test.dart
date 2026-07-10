import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/features/pantry/utils/pantry_shop_refresh_policy.dart';
import 'package:myplanr/shared/constants/household_modules.dart';

void main() {
  group('shouldSyncShopAfterPantryChange', () {
    test('returns true when shopping module is enabled', () {
      expect(
        shouldSyncShopAfterPantryChange({HouseholdModules.shopping}),
        isTrue,
      );
    });

    test('returns false when shopping module is disabled', () {
      expect(
        shouldSyncShopAfterPantryChange({HouseholdModules.pantry}),
        isFalse,
      );
    });

    test('returns false for empty module set', () {
      expect(shouldSyncShopAfterPantryChange({}), isFalse);
    });
  });
}
