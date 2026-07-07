class StandaloneReminder {
  const StandaloneReminder({
    required this.id,
    required this.householdId,
    required this.userId,
    required this.title,
    this.notes,
    required this.reminderAt,
    required this.isActive,
  });

  final String id;
  final String householdId;
  final String userId;
  final String title;
  final String? notes;
  final DateTime reminderAt;
  final bool isActive;

  factory StandaloneReminder.fromJson(Map<String, dynamic> json) {
    return StandaloneReminder(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      notes: json['notes'] as String?,
      reminderAt: DateTime.parse(json['reminder_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toInsertJson(String householdId, String userId) {
    return {
      'household_id': householdId,
      'user_id': userId,
      'title': title,
      'notes': notes,
      'reminder_at': reminderAt.toUtc().toIso8601String(),
      'is_active': isActive,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title,
      'notes': notes,
      'reminder_at': reminderAt.toUtc().toIso8601String(),
      'is_active': isActive,
    };
  }

  StandaloneReminder copyWith({
    String? title,
    String? notes,
    DateTime? reminderAt,
    bool? isActive,
  }) {
    return StandaloneReminder(
      id: id,
      householdId: householdId,
      userId: userId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      reminderAt: reminderAt ?? this.reminderAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
