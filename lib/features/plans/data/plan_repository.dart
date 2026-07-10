import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../shared/constants/plan_constants.dart';
import '../../../shared/models/paginated_result.dart';
import '../../../shared/utils/paginated_page_parser.dart';
import '../../../shared/models/plan.dart';
import '../../alerts/services/notification_service.dart';
import '../../auth/data/auth_repository.dart';

class OpenPlansOverview {
  const OpenPlansOverview({
    required this.totalCount,
    required this.preview,
  });

  final int totalCount;
  final List<Plan> preview;
}

class PlanRepository {
  PlanRepository(this._client);

  final SupabaseClient _client;

  static const _select = '''
    *,
    about_member:household_family_members!plans_about_member_id_fkey(display_name),
    assigned_member:household_family_members!plans_assigned_to_fkey(display_name)
  ''';

  Future<List<Plan>> fetchPlans(String householdId) async {
    final data = await _client
        .from('plans')
        .select(_select)
        .eq('household_id', householdId)
        .order('due_at', ascending: true, nullsFirst: false)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => Plan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PaginatedResult<Plan>> fetchOpenPlansPage(
    String householdId, {
    required int offset,
    required int limit,
    bool mealsOnly = false,
  }) async {
    var query = _client
        .from('plans')
        .select(_select)
        .eq('household_id', householdId)
        .eq('status', 'open');
    if (mealsOnly) {
      query = query.eq('plan_type', PlanTypes.meal);
    }
    final data = await query
        .order('due_at', ascending: true, nullsFirst: false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit);
    return _parsePage(data, limit);
  }

  Future<int> fetchOpenPlanCount(String householdId) async {
    return _client
        .from('plans')
        .count(CountOption.exact)
        .eq('household_id', householdId)
        .eq('status', 'open');
  }

  static const _overviewProbeSize = 10;

  Future<OpenPlansOverview> fetchOpenPlansOverview(String householdId) async {
    const probe = _overviewProbeSize;
    final data = await _client
        .from('plans')
        .select(_select)
        .eq('household_id', householdId)
        .eq('status', 'open')
        .order('due_at', ascending: true, nullsFirst: false)
        .order('created_at', ascending: false)
        .range(0, probe);
    final rows = (data as List)
        .map((e) => Plan.fromJson(e as Map<String, dynamic>))
        .toList();
    if (rows.length <= probe) {
      return OpenPlansOverview(totalCount: rows.length, preview: rows);
    }
    final count = await fetchOpenPlanCount(householdId);
    return OpenPlansOverview(
      totalCount: count,
      preview: rows.sublist(0, probe),
    );
  }

  Future<List<Plan>> fetchOpenPlansPreview(
    String householdId, {
    int limit = 10,
  }) async {
    final data = await _client
        .from('plans')
        .select(_select)
        .eq('household_id', householdId)
        .eq('status', 'open')
        .order('due_at', ascending: true, nullsFirst: false)
        .order('created_at', ascending: false)
        .range(0, limit - 1);
    return (data as List)
        .map((e) => Plan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Plan>> fetchTodayMealPlans(String householdId) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    final data = await _client
        .from('plans')
        .select(_select)
        .eq('household_id', householdId)
        .eq('status', 'open')
        .eq('plan_type', PlanTypes.meal)
        .gte('due_at', start.toUtc().toIso8601String())
        .lt('due_at', end.toUtc().toIso8601String())
        .order('due_at', ascending: true);
    return (data as List)
        .map((e) => Plan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<bool> hasAnyPlan(String householdId) async {
    final data = await _client
        .from('plans')
        .select('id')
        .eq('household_id', householdId)
        .limit(1)
        .maybeSingle();
    return data != null;
  }

  PaginatedResult<Plan> _parsePage(dynamic data, int limit) {
    final parsed = parsePaginatedPage(data, limit, Plan.fromJson);
    return PaginatedResult(items: parsed.items, hasMore: parsed.hasMore);
  }

  Future<List<Plan>> fetchOpenPlansWithReminders(String householdId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('plans')
        .select(_select)
        .eq('household_id', householdId)
        .eq('status', 'open')
        .eq('reminder_enabled', true)
        .or('reminder_notify_user_id.eq.$userId,reminder_notify_user_id.is.null');
    return (data as List)
        .map((e) => Plan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Plan?> fetchPlan(String id) async {
    final data = await _client
        .from('plans')
        .select(_select)
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return Plan.fromJson(data);
  }

  Future<Plan> createPlan(Plan plan, String householdId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not signed in');

    final data = await _client
        .from('plans')
        .insert(plan.toInsertJson(householdId, userId))
        .select(_select)
        .single();

    final created = Plan.fromJson(data);
    await _syncReminder(created, userId);
    return created;
  }

  Future<Plan> updatePlan(Plan plan) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not signed in');

    final data = await _client
        .from('plans')
        .update(plan.toUpdateJson(userId))
        .eq('id', plan.id)
        .select(_select)
        .single();

    final updated = Plan.fromJson(data);
    await _syncReminder(updated, userId);
    return updated;
  }

  Future<void> completePlan(String planId) async {
    await _client.rpc('complete_plan', params: {'p_plan_id': planId});
    await NotificationService.instance.cancelPlanReminder(planId);
  }

  Future<void> deletePlan(String planId) async {
    await NotificationService.instance.cancelPlanReminder(planId);
    await _client.from('plans').delete().eq('id', planId);
  }

  Future<void> rescheduleAllReminders(String householdId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final plans = await fetchOpenPlansWithReminders(householdId);
    for (final plan in plans) {
      await _syncReminder(plan, userId);
    }
  }

  Future<void> _syncReminder(Plan plan, String userId) async {
    final notifyId = plan.reminderNotifyUserId ?? plan.createdBy;
    if (notifyId != userId) {
      await NotificationService.instance.cancelPlanReminder(plan.id);
      return;
    }

    if (plan.isOpen &&
        plan.reminderEnabled &&
        plan.reminderAt != null &&
        plan.reminderAt!.isAfter(DateTime.now())) {
      await NotificationService.instance.schedulePlanReminder(
        planId: plan.id,
        title: plan.title,
        body: plan.description?.trim().isNotEmpty == true
            ? plan.description!.trim()
            : PlanTypes.labelFor(plan.planType),
        reminderAt: plan.reminderAt!,
      );
    } else {
      await NotificationService.instance.cancelPlanReminder(plan.id);
    }
  }
}

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return PlanRepository(ref.watch(supabaseClientProvider));
});

final openPlansOverviewProvider =
    FutureProvider<OpenPlansOverview>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) {
    return const OpenPlansOverview(totalCount: 0, preview: []);
  }
  return ref.watch(planRepositoryProvider).fetchOpenPlansOverview(householdId);
});

bool isPlanDueToday(DateTime? dueAt) {
  if (dueAt == null) return false;
  final local = dueAt.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  return !local.isBefore(today) && local.isBefore(tomorrow);
}

final todayMealPlansProvider = FutureProvider<List<Plan>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return [];
  return ref.watch(planRepositoryProvider).fetchTodayMealPlans(householdId);
});

final hasAnyPlanProvider = FutureProvider<bool>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return false;
  return ref.watch(planRepositoryProvider).hasAnyPlan(householdId);
});

Map<String, List<Plan>> groupTodayMealsBySlot(List<Plan> meals) {
  final grouped = <String, List<Plan>>{};
  for (final meal in meals) {
    final slot = meal.mealSlot;
    if (slot == null) continue;
    grouped.putIfAbsent(slot, () => []).add(meal);
  }
  return grouped;
}

List<Plan> unassignedTodayMeals(List<Plan> meals) {
  return meals.where((meal) => meal.mealSlot == null).toList();
}

final planProvider = FutureProvider.family<Plan?, String>((ref, id) async {
  return ref.watch(planRepositoryProvider).fetchPlan(id);
});
