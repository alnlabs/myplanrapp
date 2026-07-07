class UserProfile {
  const UserProfile({
    required this.id,
    this.displayName,
    this.activeHouseholdId,
  });

  final String id;
  final String? displayName;
  final String? activeHouseholdId;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      activeHouseholdId: json['active_household_id'] as String?,
    );
  }

  bool get hasHousehold => activeHouseholdId != null;
}
