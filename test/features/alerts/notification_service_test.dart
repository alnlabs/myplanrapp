import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/features/alerts/data/notification_alert_type.dart';
import 'package:myplanr/features/alerts/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('NotificationService scheduling guards', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({'notifications_enabled': true});
    });

    test('schedulePlanReminder skips past reminder times', () async {
      await NotificationService.instance.schedulePlanReminder(
        planId: 'plan-past',
        title: 'Breakfast',
        body: 'Cook oats',
        reminderAt: DateTime(2000, 1, 1, 8),
      );
    });

    test('scheduleSubscriptionReminder skips past reminder times', () async {
      await NotificationService.instance.scheduleSubscriptionReminder(
        subscriptionId: 'sub-past',
        title: 'Netflix',
        body: 'Due today',
        reminderAt: DateTime(1999, 12, 31),
      );
    });

    test('scheduleStandaloneReminder skips past reminder times', () async {
      await NotificationService.instance.scheduleStandaloneReminder(
        reminderId: 'rem-past',
        title: 'Call plumber',
        body: 'Follow up',
        reminderAt: DateTime(2000, 6, 1, 9),
      );
    });

    test('showTestAlert returns false when notifications disabled in prefs',
        () async {
      SharedPreferences.setMockInitialValues({'notifications_enabled': false});

      final sent = await NotificationService.instance.showTestAlert();

      expect(sent, isFalse);
    });

    test('previewAlertSound returns false when notifications disabled in prefs',
        () async {
      SharedPreferences.setMockInitialValues({'notifications_enabled': false});

      final sent = await NotificationService.instance.previewAlertSound(
        NotificationAlertType.medicineReminders,
      );

      expect(sent, isFalse);
    });
  });
}
