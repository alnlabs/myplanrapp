import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/paginated_result.dart';
import '../../../shared/models/plan.dart';
import '../../../shared/providers/paginated_list_notifier.dart';
import '../../../shared/providers/paginated_list_state.dart';
import '../../auth/data/auth_repository.dart';
import 'plan_repository.dart';
import 'plans_filter.dart';

class PlansListNotifier extends PaginatedListNotifier<Plan> {
  PlansFilter _filter = PlansFilter.all;

  PlansFilter get filter => _filter;

  void setFilter(PlansFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    refresh();
  }

  @override
  Future<String?> get householdId async {
    final profile = await ref.read(userProfileProvider.future);
    return profile?.activeHouseholdId;
  }

  @override
  Future<PaginatedResult<Plan>> fetchPage(
    String householdId,
    int offset,
    int limit,
  ) {
    return ref.read(planRepositoryProvider).fetchOpenPlansPage(
          householdId,
          offset: offset,
          limit: limit,
          mealsOnly: _filter == PlansFilter.meals,
        );
  }
}

final plansListProvider =
    NotifierProvider<PlansListNotifier, PaginatedListState<Plan>>(
  PlansListNotifier.new,
);

Future<void> refreshPlansData(WidgetRef ref) async {
  await ref.read(plansListProvider.notifier).refresh();
  ref.invalidate(openPlansOverviewProvider);
  ref.invalidate(todayMealPlansProvider);
  ref.invalidate(hasAnyPlanProvider);
}
