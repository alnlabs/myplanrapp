import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../shared/models/family_member.dart';
import '../../auth/data/auth_repository.dart';

class FamilyRepository {
  FamilyRepository(this._client);

  final SupabaseClient _client;

  Future<List<FamilyMember>> fetchRoster(String householdId) async {
    final data = await _client
        .from('household_family_members')
        .select(
          '*, household_member_details(avatar_url), '
          'profiles!household_family_members_user_id_fkey(display_name, username)',
        )
        .eq('household_id', householdId)
        .order('created_at');
    return (data as List)
        .map((e) => FamilyMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FamilyMember?> fetchMember(String id) async {
    final data = await _client
        .from('household_family_members')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return FamilyMember.fromJson(data);
  }

  Future<FamilyMember?> fetchMemberForUser({
    required String householdId,
    required String userId,
  }) async {
    final data = await _client
        .from('household_family_members')
        .select(
          '*, household_member_details(avatar_url), '
          'profiles!household_family_members_user_id_fkey(display_name, username)',
        )
        .eq('household_id', householdId)
        .eq('user_id', userId)
        .maybeSingle();
    if (data == null) return null;
    return FamilyMember.fromJson(data);
  }

  Future<FamilyMemberDetails?> fetchDetails(String familyMemberId) async {
    final data = await _client.rpc(
      'get_member_details_for_viewer',
      params: {'p_family_member_id': familyMemberId},
    );
    if (data == null) return null;
    return FamilyMemberDetails.fromJson(data as Map<String, dynamic>);
  }

  Future<String> addRosterMember({
    required String householdId,
    required String displayName,
    required String relationship,
    String? phone,
    DateTime? dateOfBirth,
  }) async {
    final result = await _client.rpc<String>('add_roster_family_member', params: {
      'p_household_id': householdId,
      'p_display_name': displayName,
      'p_relationship': relationship,
      'p_phone': phone,
      'p_date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
    });
    return result;
  }

  Future<String> inviteAppMember({
    required String householdId,
    required String email,
    required String relationship,
  }) async {
    final result = await _client.rpc<String>('invite_app_family_member', params: {
      'p_household_id': householdId,
      'p_email': email.trim().toLowerCase(),
      'p_relationship': relationship,
    });
    return result;
  }

  Future<void> removeRosterMember(String familyMemberId) async {
    await _client.rpc('remove_family_roster_member', params: {
      'p_family_member_id': familyMemberId,
    });
  }

  Future<void> convertToAppMember({
    required String familyMemberId,
    required String email,
  }) async {
    await _client.rpc('convert_roster_to_app', params: {
      'p_family_member_id': familyMemberId,
      'p_email': email.trim().toLowerCase(),
    });
  }

  Future<void> convertToProfileOnly(String familyMemberId) async {
    await _client.rpc('convert_app_to_roster', params: {
      'p_family_member_id': familyMemberId,
    });
  }

  Future<void> upsertDetails(
    String familyMemberId,
    FamilyMemberDetails details,
  ) async {
    await _client.rpc('upsert_member_details', params: {
      'p_family_member_id': familyMemberId,
      'p_details': details.toJson(),
    });
  }
}

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return FamilyRepository(ref.watch(supabaseClientProvider));
});

final familyRosterProvider = FutureProvider<List<FamilyMember>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return [];
  return ref.watch(familyRepositoryProvider).fetchRoster(householdId);
});

final familyMemberProvider =
    FutureProvider.family<FamilyMember?, String>((ref, id) async {
  return ref.watch(familyRepositoryProvider).fetchMember(id);
});

final familyMemberDetailsProvider =
    FutureProvider.family<FamilyMemberDetails?, String>((ref, id) async {
  return ref.watch(familyRepositoryProvider).fetchDetails(id);
});

final currentUserFamilyMemberProvider = FutureProvider<FamilyMember?>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final userId = ref.watch(currentUserIdProvider);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null || userId == null) return null;
  return ref.watch(familyRepositoryProvider).fetchMemberForUser(
        householdId: householdId,
        userId: userId,
      );
});
