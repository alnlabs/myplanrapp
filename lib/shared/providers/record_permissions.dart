import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/supabase_providers.dart';
import '../../features/household/data/household_repository.dart';

bool canManageRecord({
  required String? createdBy,
  required String? currentUserId,
  required bool isOwner,
}) {
  if (currentUserId == null) return false;
  if (isOwner) return true;
  return createdBy != null && createdBy == currentUserId;
}

final isHouseholdOwnerProvider = Provider<bool>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return false;
  final members = ref.watch(householdMembersProvider).valueOrNull;
  return members?.any((m) => m.userId == userId && m.role == 'owner') ?? false;
});

/// Maps a household member's user id to their display name.
final memberNamesProvider = Provider<Map<String, String>>((ref) {
  final members = ref.watch(householdMembersProvider).valueOrNull ?? [];
  return {
    for (final m in members)
      if (m.displayName != null) m.userId: m.displayName!,
  };
});
