import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../shared/models/subscription.dart';
import '../../alerts/services/notification_service.dart';
import '../../auth/data/auth_repository.dart';

class SubscriptionRepository {
  SubscriptionRepository(this._client);

  final SupabaseClient _client;

  Future<List<Subscription>> fetchSubscriptions(String householdId) async {
    final data = await _client
        .from('subscriptions')
        .select()
        .eq('household_id', householdId)
        .eq('is_active', true)
        .order('name');
    return (data as List)
        .map((e) => Subscription.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Subscription>> fetchDueSoon(String householdId) async {
    final subs = await fetchSubscriptions(householdId);
    return subs.where((s) => s.isDueSoon).toList()
      ..sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));
  }

  Future<Subscription?> fetchSubscription(String id) async {
    final data =
        await _client.from('subscriptions').select().eq('id', id).maybeSingle();
    if (data == null) return null;
    return Subscription.fromJson(data);
  }

  Future<Subscription> createSubscription(
    Subscription subscription,
    String householdId,
  ) async {
    final userId = _client.auth.currentUser?.id;
    final data = await _client
        .from('subscriptions')
        .insert(subscription.toJson(householdId, userId))
        .select()
        .single();
    final created = Subscription.fromJson(data);
    await _syncReminder(created, userId);
    return created;
  }

  Future<Subscription> updateSubscription(Subscription subscription) async {
    final userId = _client.auth.currentUser?.id;
    final payload = subscription.toJson(subscription.householdId, userId);
    payload.remove('household_id');
    payload.remove('created_by');

    final data = await _client
        .from('subscriptions')
        .update(payload)
        .eq('id', subscription.id)
        .select()
        .single();
    final updated = Subscription.fromJson(data);
    await _syncReminder(updated, userId);
    return updated;
  }

  Future<void> deleteSubscription(String id) async {
    await NotificationService.instance.cancelSubscriptionReminder(id);
    await _client.from('subscriptions').delete().eq('id', id);
  }

  Future<void> rescheduleAllReminders(String householdId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final subs = await fetchSubscriptions(householdId);
    for (final sub in subs) {
      await _syncReminder(sub, userId);
    }
  }

  Future<void> _syncReminder(Subscription sub, String? userId) async {
    if (sub.createdBy != userId) {
      await NotificationService.instance.cancelSubscriptionReminder(sub.id);
      return;
    }

    final reminderAt = sub.reminderAt;
    if (sub.isActive &&
        sub.reminderEnabled &&
        reminderAt != null &&
        reminderAt.isAfter(DateTime.now())) {
      await NotificationService.instance.scheduleSubscriptionReminder(
        subscriptionId: sub.id,
        title: sub.name,
        body: 'Due ${sub.nextDueDate.toString().split(' ').first}',
        reminderAt: reminderAt,
      );
    } else {
      await NotificationService.instance.cancelSubscriptionReminder(sub.id);
    }
  }
}

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(ref.watch(supabaseClientProvider));
});

final subscriptionsProvider = FutureProvider<List<Subscription>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return [];
  return ref.watch(subscriptionRepositoryProvider).fetchSubscriptions(householdId);
});

final subscriptionsDueSoonProvider = FutureProvider<List<Subscription>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return [];
  return ref.watch(subscriptionRepositoryProvider).fetchDueSoon(householdId);
});

final subscriptionProvider =
    FutureProvider.family<Subscription?, String>((ref, id) async {
  return ref.watch(subscriptionRepositoryProvider).fetchSubscription(id);
});
