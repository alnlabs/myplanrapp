import '../constants/family_relationships.dart';
import '../utils/member_display_name.dart';

class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.householdId,
    required this.displayName,
    required this.relationship,
    required this.memberType,
    this.userId,
    this.invitedEmail,
    this.inviteStatus,
    this.phone,
    this.dateOfBirth,
    this.createdBy,
    this.avatarUrl,
    this.profileDisplayName,
    this.profileUsername,
  });

  final String id;
  final String householdId;
  final String? userId;
  final String displayName;
  final String relationship;
  final String memberType;
  final String? invitedEmail;
  final String? inviteStatus;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? createdBy;
  final String? avatarUrl;
  final String? profileDisplayName;
  final String? profileUsername;

  bool get isAppMember => memberType == 'app';
  bool get isRosterOnly => memberType == 'roster';
  bool get isPendingInvite => inviteStatus == 'pending';

  String get relationshipLabel => FamilyRelationships.labelFor(relationship);

  /// Name shown in family lists: full name first, then username, then email.
  String get listLabel => memberListLabel(
        profileDisplayName: profileDisplayName,
        rosterDisplayName: displayName,
        username: profileUsername,
        email: invitedEmail,
      );

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'];
    String? profileDisplayName;
    String? profileUsername;
    if (profile is Map<String, dynamic>) {
      profileDisplayName = profile['display_name'] as String?;
      profileUsername = profile['username'] as String?;
    }

    return FamilyMember(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      userId: json['user_id'] as String?,
      displayName: json['display_name'] as String,
      relationship: json['relationship'] as String,
      memberType: json['member_type'] as String,
      invitedEmail: json['invited_email'] as String?,
      inviteStatus: json['invite_status'] as String?,
      phone: json['phone'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      createdBy: json['created_by'] as String?,
      avatarUrl: _parseAvatarUrl(json),
      profileDisplayName: profileDisplayName,
      profileUsername: profileUsername,
    );
  }

  static String? _parseAvatarUrl(Map<String, dynamic> json) {
    final nested = json['household_member_details'];
    if (nested is Map<String, dynamic>) {
      return nested['avatar_url'] as String?;
    }
    if (nested is List && nested.isNotEmpty) {
      final first = nested.first;
      if (first is Map<String, dynamic>) {
        return first['avatar_url'] as String?;
      }
    }
    return json['avatar_url'] as String?;
  }
}

class MemberVisibilityKeys {
  MemberVisibilityKeys._();

  static const phone = 'phone';
  static const health = 'health';
  static const emergency = 'emergency';

  static const all = [phone, health, emergency];
}

class ClothingSizeKeys {
  ClothingSizeKeys._();

  static const shirt = 'shirt';
  static const pants = 'pants';
  static const shoes = 'shoes';
}

class FamilyMemberDetails {
  const FamilyMemberDetails({
    required this.familyMemberId,
    required this.householdId,
    this.userId,
    this.phone,
    this.altPhone,
    this.dateOfBirth,
    this.bloodGroup,
    this.allergies,
    this.medicines,
    this.doctorName,
    this.doctorPhone,
    this.dietaryPreference,
    this.foodAllergies,
    this.workPlace,
    this.schoolName,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelation,
    this.notes,
    this.avatarUrl,
    this.clothingSizes = const {},
    this.visibility = const {},
  });

  final String familyMemberId;
  final String householdId;
  final String? userId;
  final String? phone;
  final String? altPhone;
  final DateTime? dateOfBirth;
  final String? bloodGroup;
  final String? allergies;
  final String? medicines;
  final String? doctorName;
  final String? doctorPhone;
  final String? dietaryPreference;
  final String? foodAllergies;
  final String? workPlace;
  final String? schoolName;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelation;
  final String? notes;
  final String? avatarUrl;
  final Map<String, String> clothingSizes;
  final Map<String, bool> visibility;

  bool isVisible(String key) => visibility[key] ?? true;

  factory FamilyMemberDetails.fromJson(Map<String, dynamic> json) {
    return FamilyMemberDetails(
      familyMemberId: json['family_member_id'] as String,
      householdId: json['household_id'] as String,
      userId: json['user_id'] as String?,
      phone: json['phone'] as String?,
      altPhone: json['alt_phone'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      bloodGroup: json['blood_group'] as String?,
      allergies: json['allergies'] as String?,
      medicines: json['medicines'] as String?,
      doctorName: json['doctor_name'] as String?,
      doctorPhone: json['doctor_phone'] as String?,
      dietaryPreference: json['dietary_preference'] as String?,
      foodAllergies: json['food_allergies'] as String?,
      workPlace: json['work_place'] as String?,
      schoolName: json['school_name'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      emergencyContactRelation: json['emergency_contact_relation'] as String?,
      notes: json['notes'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      clothingSizes: _parseStringMap(json['clothing_sizes']),
      visibility: _parseBoolMap(json['visibility']),
    );
  }

  static Map<String, String> _parseStringMap(dynamic value) {
    if (value is! Map) return {};
    return value.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
  }

  static Map<String, bool> _parseBoolMap(dynamic value) {
    if (value is! Map) return {};
    return value.map((k, v) => MapEntry(k.toString(), v == true));
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'alt_phone': altPhone,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
      'blood_group': bloodGroup,
      'allergies': allergies,
      'medicines': medicines,
      'doctor_name': doctorName,
      'doctor_phone': doctorPhone,
      'dietary_preference': dietaryPreference,
      'food_allergies': foodAllergies,
      'work_place': workPlace,
      'school_name': schoolName,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'emergency_contact_relation': emergencyContactRelation,
      'notes': notes,
      'avatar_url': avatarUrl,
      'clothing_sizes': clothingSizes,
      'visibility': visibility,
    };
  }

  FamilyMemberDetails copyWith({
    String? phone,
    String? altPhone,
    DateTime? dateOfBirth,
    String? bloodGroup,
    String? allergies,
    String? medicines,
    String? doctorName,
    String? doctorPhone,
    String? dietaryPreference,
    String? foodAllergies,
    String? workPlace,
    String? schoolName,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    String? notes,
    String? avatarUrl,
    Map<String, String>? clothingSizes,
    Map<String, bool>? visibility,
  }) {
    return FamilyMemberDetails(
      familyMemberId: familyMemberId,
      householdId: householdId,
      userId: userId,
      phone: phone ?? this.phone,
      altPhone: altPhone ?? this.altPhone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      medicines: medicines ?? this.medicines,
      doctorName: doctorName ?? this.doctorName,
      doctorPhone: doctorPhone ?? this.doctorPhone,
      dietaryPreference: dietaryPreference ?? this.dietaryPreference,
      foodAllergies: foodAllergies ?? this.foodAllergies,
      workPlace: workPlace ?? this.workPlace,
      schoolName: schoolName ?? this.schoolName,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelation:
          emergencyContactRelation ?? this.emergencyContactRelation,
      notes: notes ?? this.notes,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      clothingSizes: clothingSizes ?? this.clothingSizes,
      visibility: visibility ?? this.visibility,
    );
  }
}
