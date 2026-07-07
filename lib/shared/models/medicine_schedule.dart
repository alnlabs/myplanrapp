class MedicineSchedule {
  const MedicineSchedule({
    required this.id,
    required this.familyMemberId,
    required this.householdId,
    required this.medicineName,
    this.dosage,
    this.timesPerDay = const [],
    this.isActive = true,
    this.reminderNotifyUserId,
    this.memberDisplayName,
  });

  final String id;
  final String familyMemberId;
  final String householdId;
  final String medicineName;
  final String? dosage;
  final List<String> timesPerDay;
  final bool isActive;
  final String? reminderNotifyUserId;
  final String? memberDisplayName;

  String get timesLabel =>
      timesPerDay.isEmpty ? '' : timesPerDay.join(', ');

  factory MedicineSchedule.fromJson(Map<String, dynamic> json) {
    final times = json['times_per_day'];
    return MedicineSchedule(
      id: json['id'] as String,
      familyMemberId: json['family_member_id'] as String,
      householdId: json['household_id'] as String,
      medicineName: json['medicine_name'] as String,
      dosage: json['dosage'] as String?,
      timesPerDay: times is List
          ? times.map((e) => e.toString()).toList()
          : const [],
      isActive: json['is_active'] as bool? ?? true,
      reminderNotifyUserId: json['reminder_notify_user_id'] as String?,
      memberDisplayName: _memberName(json),
    );
  }

  static String? _memberName(Map<String, dynamic> json) {
    final nested = json['household_family_members'];
    if (nested is Map<String, dynamic>) {
      return nested['display_name'] as String?;
    }
    if (nested is List && nested.isNotEmpty) {
      final first = nested.first;
      if (first is Map<String, dynamic>) {
        return first['display_name'] as String?;
      }
    }
    return null;
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'family_member_id': familyMemberId,
      'household_id': householdId,
      'medicine_name': medicineName,
      'dosage': dosage,
      'times_per_day': timesPerDay,
      'is_active': isActive,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'medicine_name': medicineName,
      'dosage': dosage,
      'times_per_day': timesPerDay,
      'is_active': isActive,
    };
  }
}
