import 'account_deletion_status.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    this.displayName,
    this.username,
    this.activeHouseholdId,
    this.deletedAt,
  });

  static const deletionGracePeriod = Duration(days: 30);

  final String id;
  final String? displayName;
  final String? username;
  final String? activeHouseholdId;
  final DateTime? deletedAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      username: json['username'] as String?,
      activeHouseholdId: json['active_household_id'] as String?,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  bool get hasHousehold => activeHouseholdId != null;

  AccountDeletionStatus get deletionStatus =>
      AccountDeletionStatus.fromProfile(deletedAt);

  bool get isPendingDeletion => deletionStatus.isPending;

  DateTime? get deletionPurgeAt => deletionStatus.purgeAt;
}
