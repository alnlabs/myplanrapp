import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../shared/models/household.dart';
import '../../auth/data/auth_repository.dart';

class HouseholdRepository {
  HouseholdRepository(this._client);

  final SupabaseClient _client;

  Future<String> createHousehold(String name) async {
    final result = await _client.rpc<String>('create_household', params: {
      'p_name': name,
    });
    return result;
  }

  Future<void> acceptInvite(String householdId) async {
    await _client.rpc('accept_household_invite', params: {
      'p_household_id': householdId,
    });
  }

  Future<void> setActiveHousehold(String householdId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('profiles').update({
      'active_household_id': householdId,
    }).eq('id', userId);
  }

  Future<Household?> fetchActiveHousehold(String? householdId) async {
    if (householdId == null) return null;
    final data = await _client
        .from('households')
        .select()
        .eq('id', householdId)
        .maybeSingle();
    if (data == null) return null;
    return Household.fromJson(data);
  }

  Future<List<HouseholdMember>> fetchMembers(String householdId) async {
    final data = await _client
        .from('household_memberships')
        .select('id, user_id, role, profiles(display_name)')
        .eq('household_id', householdId)
        .order('joined_at');
    return (data as List)
        .map((e) => HouseholdMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> inviteMember(String householdId, String email) async {
    final userId = _client.auth.currentUser?.id;
    await _client.from('household_invites').insert({
      'household_id': householdId,
      'invited_email': email.trim().toLowerCase(),
      'invited_by': userId,
    });
  }

  Future<List<Map<String, dynamic>>> fetchSentPendingInvites(
    String householdId,
  ) async {
    final data = await _client
        .from('household_invites')
        .select('id, invited_email, created_at')
        .eq('household_id', householdId)
        .eq('status', 'pending')
        .order('created_at');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<void> leaveHousehold(String householdId) async {
    await _client.rpc('leave_household', params: {
      'p_household_id': householdId,
    });
  }

  Future<void> removeMember(String householdId, String userId) async {
    await _client.rpc('remove_household_member', params: {
      'p_household_id': householdId,
      'p_user_id': userId,
    });
  }

  Future<List<Map<String, dynamic>>> fetchPendingInvitesForUser() async {
    final email = _client.auth.currentUser?.email;
    if (email == null) return [];
    final data = await _client
        .from('household_invites')
        .select('id, household_id, households(name)')
        .eq('status', 'pending')
        .ilike('invited_email', email);
    return (data as List).cast<Map<String, dynamic>>();
  }
}

final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  return HouseholdRepository(ref.watch(supabaseClientProvider));
});

final activeHouseholdProvider = FutureProvider<Household?>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return ref
      .watch(householdRepositoryProvider)
      .fetchActiveHousehold(profile?.activeHouseholdId);
});

final householdMembersProvider = FutureProvider<List<HouseholdMember>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return [];
  return ref.watch(householdRepositoryProvider).fetchMembers(householdId);
});

final sentPendingInvitesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return [];
  return ref
      .watch(householdRepositoryProvider)
      .fetchSentPendingInvites(householdId);
});
