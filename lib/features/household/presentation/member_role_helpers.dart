import '../../../core/strings/app_strings.dart';
import '../../../shared/models/household.dart';

String roleLabel(String role) {
  switch (role) {
    case 'owner':
      return AppStrings.roleOwner;
    case 'co_owner':
      return AppStrings.roleCoOwner;
    default:
      return AppStrings.roleMember;
  }
}

HouseholdMember? membershipForUser(
  List<HouseholdMember> members,
  String? userId,
) {
  if (userId == null) return null;
  for (final member in members) {
    if (member.userId == userId) return member;
  }
  return null;
}

bool canChangeRole({
  required bool isOwner,
  required String? targetUserId,
  required String? currentUserId,
  required String targetRole,
}) {
  if (!isOwner || targetUserId == null) return false;
  if (targetUserId == currentUserId) return false;
  if (targetRole == 'owner') return false;
  return true;
}
