import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../shared/constants/plan_constants.dart';
import '../../../shared/models/plan.dart';
import '../../alerts/services/notification_service.dart';
import '../../auth/data/auth_repository.dart';

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
        body: PlanTypes.labelFor(plan.planType),
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

final plansProvider = FutureProvider<List<Plan>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return [];
  return ref.watch(planRepositoryProvider).fetchPlans(householdId);
});

final openPlansProvider = FutureProvider<List<Plan>>((ref) async {
  final plans = await ref.watch(plansProvider.future);
  return plans.where((p) => p.isOpen).toList();
});

final planProvider = FutureProvider.family<Plan?, String>((ref, id) async {
  return ref.watch(planRepositoryProvider).fetchPlan(id);
});
