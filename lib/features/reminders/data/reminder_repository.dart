import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../shared/constants/plan_constants.dart';
import '../../../shared/models/app_reminder_item.dart';
import '../../../shared/models/medicine_schedule.dart';
import '../../../shared/models/plan.dart';
import '../../../shared/models/standalone_reminder.dart';
import '../../../shared/models/subscription.dart';
import '../../../shared/utils/schedule_time_parser.dart';
import '../../alerts/services/notification_service.dart';
import '../../auth/data/auth_repository.dart';
import '../../household/data/medicine_schedule_repository.dart';
import '../../plans/data/plan_repository.dart';
import '../../subscriptions/data/subscription_repository.dart';

class ReminderRepository {
  ReminderRepository(this._client, this._ref);

  final SupabaseClient _client;
  final Ref _ref;

  Future<List<AppReminderItem>> fetchAll(String householdId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final results = await Future.wait([
      _fetchStandaloneItems(householdId, userId),
      _fetchPlanItems(householdId, userId),
      _fetchSubscriptionItems(householdId, userId),
      _fetchMedicineItems(householdId, userId),
    ]);

    final items = results.expand((list) => list).toList();
    items.sort(_compareItems);
    return items;
  }

  Future<List<StandaloneReminder>> fetchStandalone(String householdId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('reminders')
        .select()
        .eq('household_id', householdId)
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('reminder_at');
    return (data as List)
        .map((e) => StandaloneReminder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StandaloneReminder?> fetchStandaloneById(String id) async {
    final data =
        await _client.from('reminders').select().eq('id', id).maybeSingle();
    if (data == null) return null;
    return StandaloneReminder.fromJson(data);
  }

  Future<StandaloneReminder> createStandalone({
    required String householdId,
    required String title,
    String? notes,
    required DateTime reminderAt,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not signed in');

    final reminder = StandaloneReminder(
      id: '',
      householdId: householdId,
      userId: userId,
      title: title.trim(),
      notes: notes?.trim().isEmpty ?? true ? null : notes!.trim(),
      reminderAt: reminderAt,
      isActive: true,
    );

    final data = await _client
        .from('reminders')
        .insert(reminder.toInsertJson(householdId, userId))
        .select()
        .single();

    final created = StandaloneReminder.fromJson(data);
    await _syncStandalone(created);
    return created;
  }

  Future<StandaloneReminder> updateStandalone(StandaloneReminder reminder) async {
    final data = await _client
        .from('reminders')
        .update(reminder.toUpdateJson())
        .eq('id', reminder.id)
        .select()
        .single();

    final updated = StandaloneReminder.fromJson(data);
    await _syncStandalone(updated);
    return updated;
  }

  Future<void> deleteStandalone(String id) async {
    await NotificationService.instance.cancelStandaloneReminder(id);
    await _client.from('reminders').delete().eq('id', id);
  }

  Future<void> updatePlanReminder({
    required String planId,
    required DateTime reminderAt,
    required bool enabled,
  }) async {
    final plan = await _ref.read(planRepositoryProvider).fetchPlan(planId);
    if (plan == null) throw Exception('Plan not found');

    final updated = Plan(
      id: plan.id,
      householdId: plan.householdId,
      createdBy: plan.createdBy,
      scope: plan.scope,
      planType: plan.planType,
      title: plan.title,
      description: plan.description,
      status: plan.status,
      dueAt: plan.dueAt,
      reminderEnabled: enabled,
      reminderAt: enabled ? reminderAt : null,
      aboutMemberId: plan.aboutMemberId,
      assignedTo: plan.assignedTo,
      reminderNotifyUserId: plan.reminderNotifyUserId,
      recipeId: plan.recipeId,
      completedAt: plan.completedAt,
      aboutMemberName: plan.aboutMemberName,
      assignedToName: plan.assignedToName,
    );
    await _ref.read(planRepositoryProvider).updatePlan(updated);
  }

  Future<void> updateSubscriptionReminder({
    required String subscriptionId,
    required DateTime reminderAt,
    required bool enabled,
  }) async {
    final sub =
        await _ref.read(subscriptionRepositoryProvider).fetchSubscription(subscriptionId);
    if (sub == null) throw Exception('Subscription not found');

    final updated = Subscription(
      id: sub.id,
      householdId: sub.householdId,
      createdBy: sub.createdBy,
      name: sub.name,
      amount: sub.amount,
      currency: sub.currency,
      billingCycle: sub.billingCycle,
      dueDay: sub.dueDay,
      dueMonth: sub.dueMonth,
      autoRenew: sub.autoRenew,
      reminderEnabled: enabled,
      reminderDaysBefore: sub.reminderDaysBefore,
      reminderAt: enabled ? reminderAt : null,
      lastPaidExpenseId: sub.lastPaidExpenseId,
      isActive: sub.isActive,
      notes: sub.notes,
    );
    await _ref.read(subscriptionRepositoryProvider).updateSubscription(updated);
  }

  Future<void> removeLinkedReminder(AppReminderItem item) async {
    switch (item.sourceType) {
      case ReminderSourceType.plan:
        await updatePlanReminder(
          planId: item.sourceId,
          reminderAt: item.reminderAt ?? DateTime.now(),
          enabled: false,
        );
      case ReminderSourceType.subscription:
        await updateSubscriptionReminder(
          subscriptionId: item.sourceId,
          reminderAt: item.reminderAt ?? DateTime.now(),
          enabled: false,
        );
      case ReminderSourceType.medicine:
        final householdId =
            (await _ref.read(userProfileProvider.future))?.activeHouseholdId;
        if (householdId == null) return;
        final schedules = await _ref
            .read(medicineScheduleRepositoryProvider)
            .fetchSchedulesForReminders(householdId);
        final schedule = schedules.where((s) => s.id == item.sourceId).firstOrNull;
        if (schedule == null) return;

        final timeIndex = item.medicineTimeIndex;
        final updatedTimes = [...schedule.timesPerDay];
        if (timeIndex != null &&
            timeIndex >= 0 &&
            timeIndex < updatedTimes.length) {
          updatedTimes.removeAt(timeIndex);
        }

        await _ref.read(medicineScheduleRepositoryProvider).updateSchedule(
              MedicineSchedule(
                id: schedule.id,
                familyMemberId: schedule.familyMemberId,
                householdId: schedule.householdId,
                medicineName: schedule.medicineName,
                dosage: schedule.dosage,
                timesPerDay: updatedTimes,
                isActive: updatedTimes.isNotEmpty,
                reminderNotifyUserId: schedule.reminderNotifyUserId,
                memberDisplayName: schedule.memberDisplayName,
              ),
            );
      case ReminderSourceType.standalone:
        await deleteStandalone(item.sourceId);
    }
  }

  Future<void> rescheduleAllReminders(String householdId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final standalone = await fetchStandalone(householdId);
    for (final reminder in standalone) {
      await _syncStandalone(reminder);
    }
  }

  Future<void> _syncStandalone(StandaloneReminder reminder) async {
    await NotificationService.instance.cancelStandaloneReminder(reminder.id);

    if (!reminder.isActive) return;
    if (!reminder.reminderAt.isAfter(DateTime.now())) return;

    await NotificationService.instance.scheduleStandaloneReminder(
      reminderId: reminder.id,
      title: reminder.title,
      body: reminder.notes ?? reminder.title,
      reminderAt: reminder.reminderAt,
    );
  }

  Future<List<AppReminderItem>> _fetchStandaloneItems(
    String householdId,
    String userId,
  ) async {
    final reminders = await fetchStandalone(householdId);
    return reminders
        .map(
          (r) => AppReminderItem(
            id: 'standalone_${r.id}',
            sourceType: ReminderSourceType.standalone,
            sourceId: r.id,
            title: r.title,
            subtitle: r.notes,
            reminderAt: r.reminderAt,
          ),
        )
        .toList();
  }

  Future<List<AppReminderItem>> _fetchPlanItems(
    String householdId,
    String userId,
  ) async {
    final plans =
        await _ref.read(planRepositoryProvider).fetchOpenPlansWithReminders(householdId);
    return plans
        .where((p) => p.reminderEnabled && p.reminderAt != null)
        .map(
          (plan) => AppReminderItem(
            id: 'plan_${plan.id}',
            sourceType: ReminderSourceType.plan,
            sourceId: plan.id,
            title: plan.title,
            subtitle: _planTypeLabel(plan.planType),
            reminderAt: plan.reminderAt,
          ),
        )
        .toList();
  }

  Future<List<AppReminderItem>> _fetchSubscriptionItems(
    String householdId,
    String userId,
  ) async {
    final subs =
        await _ref.read(subscriptionRepositoryProvider).fetchSubscriptions(householdId);
    return subs
        .where((s) => s.reminderEnabled && s.effectiveReminderAt != null)
        .map(
          (sub) => AppReminderItem(
            id: 'sub_${sub.id}',
            sourceType: ReminderSourceType.subscription,
            sourceId: sub.id,
            title: sub.name,
            subtitle: AppReminderLabels.subscription,
            reminderAt: sub.effectiveReminderAt,
          ),
        )
        .toList();
  }

  Future<List<AppReminderItem>> _fetchMedicineItems(
    String householdId,
    String userId,
  ) async {
    final schedules = await _ref
        .read(medicineScheduleRepositoryProvider)
        .fetchSchedulesForReminders(householdId);
    final items = <AppReminderItem>[];

    for (final schedule in schedules) {
      final memberName = schedule.memberDisplayName ?? AppReminderLabels.familyMember;
      for (var i = 0; i < schedule.timesPerDay.length; i++) {
        final rawTime = schedule.timesPerDay[i];
        final parsed = parseScheduleTime(rawTime);
        if (parsed == null) continue;
        items.add(
          AppReminderItem(
            id: 'med_${schedule.id}_$i',
            sourceType: ReminderSourceType.medicine,
            sourceId: schedule.id,
            title: schedule.medicineName,
            subtitle: '$memberName · ${formatScheduleTime(parsed)}',
            reminderAt: _nextDailyOccurrence(parsed.hour, parsed.minute),
            isRepeating: true,
            timeLabel: formatScheduleTime(parsed),
            medicineTimeIndex: i,
          ),
        );
      }
    }
    return items;
  }

  String _planTypeLabel(String planType) {
    return switch (planType) {
      PlanTypes.meal => AppReminderLabels.planMeal,
      PlanTypes.medicine => AppReminderLabels.planMedicine,
      PlanTypes.purchase => AppReminderLabels.planPurchase,
      PlanTypes.task => AppReminderLabels.planTask,
      _ => AppReminderLabels.plan,
    };
  }

  int _compareItems(AppReminderItem a, AppReminderItem b) {
    if (a.isRepeating != b.isRepeating) {
      return a.isRepeating ? 1 : -1;
    }
    final aAt = a.reminderAt;
    final bAt = b.reminderAt;
    if (aAt == null && bAt == null) return a.title.compareTo(b.title);
    if (aAt == null) return 1;
    if (bAt == null) return -1;
    return aAt.compareTo(bAt);
  }

  DateTime _nextDailyOccurrence(int hour, int minute) {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }
}

/// Labels used in repository to avoid circular imports with AppStrings.
class AppReminderLabels {
  AppReminderLabels._();

  static const subscription = 'Subscription';
  static const familyMember = 'Family member';
  static const plan = 'Plan';
  static const planMeal = 'Meal plan';
  static const planMedicine = 'Medicine plan';
  static const planPurchase = 'Purchase plan';
  static const planTask = 'Task';
}

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepository(ref.watch(supabaseClientProvider), ref);
});

final appRemindersProvider = FutureProvider<List<AppReminderItem>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return [];
  return ref.watch(reminderRepositoryProvider).fetchAll(householdId);
});

final standaloneReminderProvider =
    FutureProvider.family<StandaloneReminder?, String>((ref, id) async {
  return ref.watch(reminderRepositoryProvider).fetchStandaloneById(id);
});
