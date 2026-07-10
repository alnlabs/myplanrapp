import '../../../shared/constants/household_modules.dart';

/// Whether pantry stock changes should sync the shared shopping list.
bool shouldSyncShopAfterPantryChange(Set<String> enabledModules) {
  return enabledModules.contains(HouseholdModules.shopping);
}
