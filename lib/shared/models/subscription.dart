import '../constants/subscription_constants.dart';

class Subscription {
  const Subscription({
    required this.id,
    required this.householdId,
    required this.name,
    required this.billingCycle,
    required this.dueDay,
    this.createdBy,
    this.amount,
    this.currency = 'INR',
    this.dueMonth,
    this.autoRenew = true,
    this.reminderEnabled = false,
    this.reminderDaysBefore = 3,
    this.reminderAt,
    this.lastPaidExpenseId,
    this.isActive = true,
    this.notes,
    this.paymentMethod,
    this.paymentDetail,
  });

  final String id;
  final String householdId;
  final String? createdBy;
  final String name;
  final double? amount;
  final String currency;
  final String billingCycle;
  final int dueDay;
  final int? dueMonth;
  final bool autoRenew;
  final bool reminderEnabled;
  final int reminderDaysBefore;
  final DateTime? reminderAt;
  final String? lastPaidExpenseId;
  final bool isActive;
  final String? notes;
  final String? paymentMethod;
  final String? paymentDetail;

  String? get paymentSummary {
    if (paymentMethod == null) return null;
    final method = PaymentMethods.labelFor(paymentMethod!);
    final detail = paymentDetail?.trim();
    if (detail != null && detail.isNotEmpty) return '$method · $detail';
    return method;
  }

  DateTime get nextDueDate => computeNextDueDate(
        billingCycle: billingCycle,
        dueDay: dueDay,
        dueMonth: dueMonth,
        from: DateTime.now(),
      );

  DateTime? get effectiveReminderAt {
    if (!reminderEnabled) return null;
    if (reminderAt != null) return _resolveReminderAt(reminderAt!);
    return nextDueDate.subtract(Duration(days: reminderDaysBefore));
  }

  DateTime _resolveReminderAt(DateTime stored) {
    var at = stored.toLocal();
    var due = nextDueDate;
    while (!at.isAfter(DateTime.now())) {
      final daysBefore = DateTime(due.year, due.month, due.day)
          .difference(DateTime(at.year, at.month, at.day))
          .inDays
          .clamp(0, 30);
      due = computeNextDueDate(
        billingCycle: billingCycle,
        dueDay: dueDay,
        dueMonth: dueMonth,
        from: due.add(const Duration(days: 1)),
      );
      final dueDayDate = DateTime(due.year, due.month, due.day);
      at = DateTime(
        dueDayDate.year,
        dueDayDate.month,
        dueDayDate.day,
        stored.hour,
        stored.minute,
      ).subtract(Duration(days: daysBefore));
    }
    return at;
  }

  int get daysUntilDue {
    final due = nextDueDate;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final dueDate = DateTime(due.year, due.month, due.day);
    return dueDate.difference(today).inDays;
  }

  bool get isDueSoon => isActive && daysUntilDue >= 0 && daysUntilDue <= 7;

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      createdBy: json['created_by'] as String?,
      name: json['name'] as String,
      amount: (json['amount'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'INR',
      billingCycle: json['billing_cycle'] as String,
      dueDay: json['due_day'] as int,
      dueMonth: json['due_month'] as int?,
      autoRenew: json['auto_renew'] as bool? ?? true,
      reminderEnabled: json['reminder_enabled'] as bool? ?? false,
      reminderDaysBefore: json['reminder_days_before'] as int? ?? 3,
      reminderAt: json['reminder_at'] != null
          ? DateTime.parse(json['reminder_at'] as String)
          : null,
      lastPaidExpenseId: json['last_paid_expense_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      notes: json['notes'] as String?,
      paymentMethod: json['payment_method'] as String?,
      paymentDetail: json['payment_detail'] as String?,
    );
  }

  Map<String, dynamic> toJson(String householdId, String? userId) {
    return {
      'household_id': householdId,
      'created_by': userId,
      'name': name,
      'amount': amount,
      'currency': currency,
      'billing_cycle': billingCycle,
      'due_day': dueDay,
      'due_month': billingCycle == BillingCycles.yearly ? dueMonth : null,
      'auto_renew': autoRenew,
      'reminder_enabled': reminderEnabled,
      'reminder_days_before': reminderDaysBefore,
      'reminder_at': reminderEnabled ? reminderAt?.toUtc().toIso8601String() : null,
      'is_active': isActive,
      'notes': notes,
      'payment_method': paymentMethod,
      'payment_detail': _emptyToNull(paymentDetail),
    };
  }

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  static DateTime computeNextDueDate({
    required String billingCycle,
    required int dueDay,
    int? dueMonth,
    required DateTime from,
  }) {
    if (billingCycle == BillingCycles.yearly) {
      final month = dueMonth ?? from.month;
      var candidate = _safeDate(from.year, month, dueDay);
      if (!candidate.isAfter(from)) {
        candidate = _safeDate(from.year + 1, month, dueDay);
      }
      return candidate;
    }

    var candidate = _safeDate(from.year, from.month, dueDay);
    if (!candidate.isAfter(from)) {
      final nextMonth = from.month == 12 ? 1 : from.month + 1;
      final nextYear = from.month == 12 ? from.year + 1 : from.year;
      candidate = _safeDate(nextYear, nextMonth, dueDay);
    }
    return candidate;
  }

  static DateTime _safeDate(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day.clamp(1, lastDay));
  }
}
