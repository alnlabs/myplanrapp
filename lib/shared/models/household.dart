class Household {
  const Household({
    required this.id,
    required this.name,
    required this.ownerId,
  });

  final String id;
  final String name;
  final String ownerId;

  factory Household.fromJson(Map<String, dynamic> json) {
    return Household(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['owner_id'] as String,
    );
  }
}

class HouseholdMember {
  const HouseholdMember({
    required this.id,
    required this.userId,
    required this.role,
    this.displayName,
  });

  final String id;
  final String userId;
  final String role;
  final String? displayName;

  factory HouseholdMember.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return HouseholdMember(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      displayName: profile?['display_name'] as String?,
    );
  }
}
