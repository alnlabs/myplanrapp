class Plan {
  const Plan({
    required this.id,
    required this.householdId,
    required this.createdBy,
    required this.scope,
    required this.planType,
    required this.title,
    this.description,
    required this.status,
    this.dueAt,
    required this.reminderEnabled,
    this.reminderAt,
    this.aboutMemberId,
    this.assignedTo,
    this.reminderNotifyUserId,
    this.recipeId,
    this.mealSlot,
    this.completedAt,
    this.aboutMemberName,
    this.assignedToName,
  });

  final String id;
  final String householdId;
  final String createdBy;
  final String scope;
  final String planType;
  final String title;
  final String? description;
  final String status;
  final DateTime? dueAt;
  final bool reminderEnabled;
  final DateTime? reminderAt;
  final String? aboutMemberId;
  final String? assignedTo;
  final String? reminderNotifyUserId;
  final String? recipeId;
  final String? mealSlot;
  final DateTime? completedAt;
  final String? aboutMemberName;
  final String? assignedToName;

  bool get isOpen => status == 'open';
  bool get isPersonal => scope == 'personal';

  factory Plan.fromJson(Map<String, dynamic> json) {
    final aboutMember = json['about_member'] as Map<String, dynamic>?;
    final assignedMember = json['assigned_member'] as Map<String, dynamic>?;

    return Plan(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      createdBy: json['created_by'] as String,
      scope: json['scope'] as String,
      planType: json['plan_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      dueAt: json['due_at'] != null
          ? DateTime.parse(json['due_at'] as String)
          : null,
      reminderEnabled: json['reminder_enabled'] as bool? ?? false,
      reminderAt: json['reminder_at'] != null
          ? DateTime.parse(json['reminder_at'] as String)
          : null,
      aboutMemberId: json['about_member_id'] as String?,
      assignedTo: json['assigned_to'] as String?,
      reminderNotifyUserId: json['reminder_notify_user_id'] as String?,
      recipeId: json['recipe_id'] as String?,
      mealSlot: json['meal_slot'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      aboutMemberName: aboutMember?['display_name'] as String?,
      assignedToName: assignedMember?['display_name'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson(String householdId, String userId) {
    return {
      'household_id': householdId,
      'created_by': userId,
      'scope': scope,
      'plan_type': planType,
      'title': title,
      'description': description,
      'due_at': dueAt?.toUtc().toIso8601String(),
      'reminder_enabled': reminderEnabled,
      'reminder_at': reminderEnabled ? reminderAt?.toUtc().toIso8601String() : null,
      'about_member_id': aboutMemberId,
      'assigned_to': assignedTo,
      'reminder_notify_user_id': reminderNotifyUserId ?? userId,
      'recipe_id': recipeId,
      'meal_slot': mealSlot,
    };
  }

  Map<String, dynamic> toUpdateJson(String userId) {
    return {
      'scope': scope,
      'plan_type': planType,
      'title': title,
      'description': description,
      'due_at': dueAt?.toUtc().toIso8601String(),
      'reminder_enabled': reminderEnabled,
      'reminder_at': reminderEnabled ? reminderAt?.toUtc().toIso8601String() : null,
      'about_member_id': aboutMemberId,
      'assigned_to': assignedTo,
      'reminder_notify_user_id': reminderNotifyUserId ?? userId,
      'recipe_id': recipeId,
      'meal_slot': mealSlot,
    };
  }
}
