import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../household/data/household_settings_repository.dart';
import '../../shopping/data/shopping_list_provider.dart';
import '../utils/pantry_shop_refresh_policy.dart';
import 'pantry_items_list_provider.dart';
import 'pantry_repository.dart';

void invalidatePantryAlerts(WidgetRef ref) {
  ref.invalidate(lowStockItemsProvider);
  ref.invalidate(expiringItemsProvider);
}

/// Refresh paginated list and alert providers only.
Future<void> refreshPantryListAndAlerts(WidgetRef ref) async {
  await refreshPantryList(ref);
  invalidatePantryAlerts(ref);
}

/// After stock quantity changes — sync shop only when shopping module is on.
Future<void> refreshPantryAfterStockChange(WidgetRef ref) async {
  await refreshPantryListAndAlerts(ref);
  final modules = ref.read(enabledModulesProvider);
  if (shouldSyncShopAfterPantryChange(modules)) {
    await refreshShopFromPantry(ref);
  }
}

/// Call after pantry mutations that affect shop low-stock / attention rows.
Future<void> refreshPantryAndShop(WidgetRef ref) async {
  await refreshPantryListAndAlerts(ref);
  await refreshShopFromPantry(ref);
}
