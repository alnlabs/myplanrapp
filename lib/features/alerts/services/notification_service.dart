import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  int _notificationId(String key) => key.hashCode.abs() % 100000;

  Future<void> showLowStockAlert({
    required String itemId,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      _notificationId(itemId),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'low_stock',
          'Low stock alerts',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> schedulePlanReminder({
    required String planId,
    required String title,
    required String body,
    required DateTime reminderAt,
  }) async {
    final scheduled = tz.TZDateTime.from(reminderAt.toLocal(), tz.local);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      _notificationId('plan_$planId'),
      'Plan reminder',
      title,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'plan_reminders',
          'Plan reminders',
          channelDescription: 'Reminders for plans and tasks',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(subtitle: body),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelPlanReminder(String planId) async {
    await _plugin.cancel(_notificationId('plan_$planId'));
  }

  Future<void> scheduleSubscriptionReminder({
    required String subscriptionId,
    required String title,
    required String body,
    required DateTime reminderAt,
  }) async {
    final scheduled = tz.TZDateTime.from(reminderAt.toLocal(), tz.local);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      _notificationId('sub_$subscriptionId'),
      'Bill reminder',
      title,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'subscription_reminders',
          'Subscription reminders',
          channelDescription: 'Reminders for recurring bills and subscriptions',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(subtitle: body),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelSubscriptionReminder(String subscriptionId) async {
    await _plugin.cancel(_notificationId('sub_$subscriptionId'));
  }
}
