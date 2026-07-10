class RecurringMoneyRule {
  const RecurringMoneyRule({
    required this.id,
    required this.householdId,
    required this.entryType,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.frequency,
    required this.intervalCount,
    required this.startDate,
    required this.nextDueDate,
    this.note,
    this.incomeSource,
    this.familyMemberId,
    this.dayOfMonth,
    this.dayOfWeek,
    this.monthOfYear,
    this.endDate,
    this.isActive = true,
    this.autoLog = false,
    this.snoozeUntil,
    this.groupId,
    this.paidByMemberId,
    this.subscriptionId,
    this.categoryName,
    this.familyMemberName,
    this.groupName,
    this.subscriptionName,
  });

  final String id;
  final String householdId;
  final String entryType;
  final String title;
  final double amount;
  final String categoryId;
  final String? categoryName;
  final String? note;
  final String? incomeSource;
  final String? familyMemberId;
  final String? familyMemberName;
  final String frequency;
  final int intervalCount;
  final int? dayOfMonth;
  final int? dayOfWeek;
  final int? monthOfYear;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextDueDate;
  final bool isActive;
  final bool autoLog;
  final DateTime? snoozeUntil;
  final String? groupId;
  final String? paidByMemberId;
  final String? subscriptionId;
  final String? groupName;
  final String? subscriptionName;

  bool get isIncome => entryType == 'income';
  bool get isExpense => entryType == 'expense';

  bool get isDue {
    final today = DateTime.now();
    final due = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    final now = DateTime(today.year, today.month, today.day);
    if (snoozeUntil != null) {
      final snooze = DateTime(
        snoozeUntil!.year,
        snoozeUntil!.month,
        snoozeUntil!.day,
      );
      if (now.isBefore(snooze)) return false;
    }
    return !due.isAfter(now);
  }

  String get displayLabel =>
      isIncome && incomeSource != null && incomeSource!.trim().isNotEmpty
          ? incomeSource!.trim()
          : title;

  factory RecurringMoneyRule.fromJson(Map<String, dynamic> json) {
    final category = json['expense_categories'] as Map<String, dynamic>?;
    final member = json['household_family_members'] as Map<String, dynamic>?;
    final group = json['expense_groups'] as Map<String, dynamic>?;
    final subscription = json['subscriptions'] as Map<String, dynamic>?;
    return RecurringMoneyRule(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      entryType: json['entry_type'] as String? ?? 'income',
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      categoryId: json['category_id'] as String,
      categoryName: category?['name'] as String?,
      note: json['note'] as String?,
      incomeSource: json['income_source'] as String?,
      familyMemberId: json['family_member_id'] as String?,
      familyMemberName: member?['display_name'] as String?,
      frequency: json['frequency'] as String,
      intervalCount: json['interval_count'] as int? ?? 1,
      dayOfMonth: json['day_of_month'] as int?,
      dayOfWeek: json['day_of_week'] as int?,
      monthOfYear: json['month_of_year'] as int?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      nextDueDate: DateTime.parse(json['next_due_date'] as String),
      isActive: json['is_active'] as bool? ?? true,
      autoLog: json['auto_log'] as bool? ?? false,
      snoozeUntil: json['snooze_until'] != null
          ? DateTime.parse(json['snooze_until'] as String)
          : null,
      groupId: json['group_id'] as String?,
      paidByMemberId: json['paid_by_member_id'] as String?,
      subscriptionId: json['subscription_id'] as String?,
      groupName: group?['name'] as String?,
      subscriptionName: subscription?['name'] as String?,
    );
  }
}
