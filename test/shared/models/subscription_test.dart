import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/constants/subscription_constants.dart';
import 'package:myplanr/shared/models/subscription.dart';

Subscription _sub({
  String billingCycle = BillingCycles.monthly,
  int dueDay = 15,
  int? dueMonth,
  bool reminderEnabled = false,
  int reminderDaysBefore = 3,
  String? paymentMethod,
  String? paymentDetail,
}) {
  return Subscription(
    id: 's1',
    householdId: 'hh',
    name: 'Netflix',
    amount: 499,
    billingCycle: billingCycle,
    dueDay: dueDay,
    dueMonth: dueMonth,
    reminderEnabled: reminderEnabled,
    reminderDaysBefore: reminderDaysBefore,
    paymentMethod: paymentMethod,
    paymentDetail: paymentDetail,
  );
}

void main() {
  group('computeNextDueDate monthly', () {
    test('returns later this month when due day is ahead', () {
      final due = Subscription.computeNextDueDate(
        billingCycle: BillingCycles.monthly,
        dueDay: 20,
        from: DateTime(2026, 7, 8),
      );
      expect(due, DateTime(2026, 7, 20));
    });

    test('rolls to next month when due day passed', () {
      final due = Subscription.computeNextDueDate(
        billingCycle: BillingCycles.monthly,
        dueDay: 5,
        from: DateTime(2026, 7, 20),
      );
      expect(due, DateTime(2026, 8, 5));
    });

    test('clamps day 31 in February', () {
      final due = Subscription.computeNextDueDate(
        billingCycle: BillingCycles.monthly,
        dueDay: 31,
        from: DateTime(2026, 1, 15),
      );
      expect(due, DateTime(2026, 1, 31));
    });
  });

  group('computeNextDueDate yearly', () {
    test('uses due month and day', () {
      final due = Subscription.computeNextDueDate(
        billingCycle: BillingCycles.yearly,
        dueDay: 10,
        dueMonth: 6,
        from: DateTime(2026, 3, 1),
      );
      expect(due, DateTime(2026, 6, 10));
    });

    test('rolls to next year when date passed', () {
      final due = Subscription.computeNextDueDate(
        billingCycle: BillingCycles.yearly,
        dueDay: 1,
        dueMonth: 1,
        from: DateTime(2026, 6, 1),
      );
      expect(due, DateTime(2027, 1, 1));
    });
  });

  group('paymentSummary', () {
    test('returns null without payment method', () {
      expect(_sub().paymentSummary, isNull);
    });

    test('includes method and detail', () {
      final summary = _sub(
        paymentMethod: PaymentMethods.upi,
        paymentDetail: 'name@upi',
      ).paymentSummary;
      expect(summary, contains('UPI'));
      expect(summary, contains('name@upi'));
    });
  });

  group('effectiveReminderAt', () {
    test('returns null when reminders disabled', () {
      expect(_sub(reminderEnabled: false).effectiveReminderAt, isNull);
    });

    test('uses reminderAt when set', () {
      final at = DateTime(2026, 8, 1, 9, 0);
      final sub = Subscription(
        id: 's1',
        householdId: 'hh',
        name: 'X',
        billingCycle: BillingCycles.monthly,
        dueDay: 15,
        reminderEnabled: true,
        reminderAt: at,
      );
      expect(sub.effectiveReminderAt, isNotNull);
    });
  });

  group('fromJson and toJson', () {
    test('parses subscription fields', () {
      final sub = Subscription.fromJson({
        'id': 's1',
        'household_id': 'hh',
        'name': 'Spotify',
        'amount': 119,
        'billing_cycle': 'monthly',
        'due_day': 5,
        'reminder_enabled': true,
        'reminder_days_before': 7,
        'is_active': true,
      });
      expect(sub.name, 'Spotify');
      expect(sub.reminderDaysBefore, 7);
      expect(sub.currency, 'INR');
    });

    test('toJson nulls dueMonth for monthly billing', () {
      final json = _sub(billingCycle: BillingCycles.monthly, dueMonth: 6)
          .toJson('hh', 'user-1');
      expect(json['due_month'], isNull);
      expect(json['billing_cycle'], 'monthly');
    });

    test('toJson keeps dueMonth for yearly billing', () {
      final json = _sub(
        billingCycle: BillingCycles.yearly,
        dueMonth: 3,
      ).toJson('hh', 'user-1');
      expect(json['due_month'], 3);
    });
  });
}
