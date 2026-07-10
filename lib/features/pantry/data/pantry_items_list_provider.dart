import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/paginated_result.dart';
import '../../../shared/models/pantry_item.dart';
import '../../../shared/providers/paginated_list_notifier.dart';
import '../../../shared/providers/paginated_list_state.dart';
import '../../auth/data/auth_repository.dart';
import 'pantry_repository.dart';

class PantryItemsListNotifier extends PaginatedListNotifier<PantryItem> {
  @override
  Future<String?> get householdId async {
    final profile = await ref.read(userProfileProvider.future);
    return profile?.activeHouseholdId;
  }

  @override
  Future<PaginatedResult<PantryItem>> fetchPage(
    String householdId,
    int offset,
    int limit,
  ) {
    return ref.read(pantryRepositoryProvider).fetchItemsPage(
          householdId,
          offset: offset,
          limit: limit,
        );
  }
}

final pantryItemsListProvider =
    NotifierProvider<PantryItemsListNotifier, PaginatedListState<PantryItem>>(
  PantryItemsListNotifier.new,
);

Future<void> refreshPantryList(WidgetRef ref) async {
  await ref.read(pantryItemsListProvider.notifier).refresh();
  ref.invalidate(pantryItemCountProvider);
  ref.invalidate(pantryPickerItemsProvider);
}
