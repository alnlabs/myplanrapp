import '../constants/reminder_repeat.dart';

class StandaloneReminder {
  const StandaloneReminder({
    required this.id,
    required this.householdId,
    required this.userId,
    required this.title,
    this.notes,
    required this.reminderAt,
    required this.isActive,
    this.repeat = ReminderRepeat.none,
  });

  final String id;
  final String householdId;
  final String userId;
  final String title;
  final String? notes;
  final DateTime reminderAt;
  final bool isActive;

  /// Repeat frequency: one of [ReminderRepeat] values. `none` = one-time.
  final String repeat;

  bool get isRecurring => ReminderRepeat.isRecurring(repeat);

  factory StandaloneReminder.fromJson(Map<String, dynamic> json) {
    return StandaloneReminder(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      notes: json['notes'] as String?,
      reminderAt: DateTime.parse(json['reminder_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      repeat: ReminderRepeat.normalize(json['repeat'] as String?),
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
      'repeat': repeat,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title,
      'notes': notes,
      'reminder_at': reminderAt.toUtc().toIso8601String(),
      'is_active': isActive,
      'repeat': repeat,
    };
  }

  StandaloneReminder copyWith({
    String? title,
    String? notes,
    DateTime? reminderAt,
    bool? isActive,
    String? repeat,
  }) {
    return StandaloneReminder(
      id: id,
      householdId: householdId,
      userId: userId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      reminderAt: reminderAt ?? this.reminderAt,
      isActive: isActive ?? this.isActive,
      repeat: repeat ?? this.repeat,
    );
  }
}
