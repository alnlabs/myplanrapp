import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/shopping_list_item.dart';
import '../../auth/data/auth_repository.dart';
import 'shopping_repository.dart';

final shoppingListProvider = FutureProvider<List<ShoppingListItem>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return [];
  return ref.watch(shoppingRepositoryProvider).fetchItems(householdId);
});

/// Sync pantry low-stock / attention items into shop, then refresh the list.
Future<void> refreshShopFromPantry(WidgetRef ref) async {
  final profile = await ref.read(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return;
  await ref.read(shoppingRepositoryProvider).syncLowStockToShop(householdId);
  ref.invalidate(shoppingListProvider);
}
