import 'reminder_repeat_spec.dart';

class StandaloneReminder {
  const StandaloneReminder({
    required this.id,
    required this.householdId,
    required this.userId,
    required this.title,
    this.notes,
    required this.reminderAt,
    required this.isActive,
    this.repeatSpec = ReminderRepeatSpec.none,
  });

  final String id;
  final String householdId;
  final String userId;
  final String title;
  final String? notes;
  final DateTime reminderAt;
  final bool isActive;

  /// Full repeat pattern. `frequency == none` means a one-time reminder.
  final ReminderRepeatSpec repeatSpec;

  /// Coarse frequency string (kept for the legacy `repeat` column).
  String get repeat => repeatSpec.frequency;

  bool get isRecurring => repeatSpec.isRecurring;

  factory StandaloneReminder.fromJson(Map<String, dynamic> json) {
    return StandaloneReminder(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      notes: json['notes'] as String?,
      reminderAt: DateTime.parse(json['reminder_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      repeatSpec: ReminderRepeatSpec.fromConfig(
        json['repeat_config'] as Map<String, dynamic>?,
        legacyRepeat: json['repeat'] as String?,
      ),
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
      'repeat': repeatSpec.legacyFrequency,
      'repeat_config': repeatSpec.toConfigJson(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title,
      'notes': notes,
      'reminder_at': reminderAt.toUtc().toIso8601String(),
      'is_active': isActive,
      'repeat': repeatSpec.legacyFrequency,
      'repeat_config': repeatSpec.toConfigJson(),
    };
  }

  StandaloneReminder copyWith({
    String? title,
    String? notes,
    DateTime? reminderAt,
    bool? isActive,
    ReminderRepeatSpec? repeatSpec,
  }) {
    return StandaloneReminder(
      id: id,
      householdId: householdId,
      userId: userId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      reminderAt: reminderAt ?? this.reminderAt,
      isActive: isActive ?? this.isActive,
      repeatSpec: repeatSpec ?? this.repeatSpec,
    );
  }
}
