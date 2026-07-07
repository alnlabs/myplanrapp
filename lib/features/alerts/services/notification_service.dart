import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/logging/app_logger.dart';

const _notificationsEnabledKey = 'notifications_enabled';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

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

    await _android?.requestNotificationsPermission();
    await _ensureExactAlarmPermission();

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    if (!_initialized) await initialize();

    final android = _android;
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      await _ensureExactAlarmPermission();
      return granted ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  Future<bool> canScheduleExactReminders() async {
    final android = _android;
    if (android == null) return true;
    return await android.canScheduleExactNotifications() ?? false;
  }

  Future<void> requestExactAlarmPermission() async {
    await _ensureExactAlarmPermission(forceRequest: true);
  }

  Future<void> _ensureExactAlarmPermission({bool forceRequest = false}) async {
    final android = _android;
    if (android == null) return;

    final canExact = await android.canScheduleExactNotifications();
    if (canExact == true) return;
    if (!forceRequest) return;

    await android.requestExactAlarmsPermission();
  }

  Future<AndroidScheduleMode> _androidScheduleMode() async {
    final android = _android;
    if (android == null) return AndroidScheduleMode.exactAllowWhileIdle;

    final canExact = await android.canScheduleExactNotifications();
    if (canExact == true) return AndroidScheduleMode.exactAllowWhileIdle;

    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> _zonedSchedule({
    required int id,
    required String? title,
    required String? body,
    required tz.TZDateTime scheduled,
    required NotificationDetails details,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    if (!await _notificationsAllowed()) return;

    var mode = await _androidScheduleMode();

    Future<void> schedule(AndroidScheduleMode scheduleMode) {
      return _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        details,
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    }

    try {
      await schedule(mode);
    } on PlatformException catch (e, st) {
      final message = e.message?.toLowerCase() ?? '';
      final exactDenied = message.contains('exact') || message.contains('alarm');
      if (mode != AndroidScheduleMode.inexactAllowWhileIdle && exactDenied) {
        AppLogger.instance.warning(
          'Exact alarms not permitted; using inexact schedule',
          e,
          st,
        );
        await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
        return;
      }
      AppLogger.instance.error(
        'Failed to schedule notification',
        e,
        st,
      );
    } catch (e, st) {
      AppLogger.instance.error(
        'Failed to schedule notification',
        e,
        st,
      );
    }
  }

  Future<bool> _notificationsAllowed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_notificationsEnabledKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  int _notificationId(String key) => key.hashCode.abs() % 100000;

  Future<void> showLowStockAlert({
    required String itemId,
    required String title,
    required String body,
  }) async {
    if (!await _notificationsAllowed()) return;
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

    await _zonedSchedule(
      id: _notificationId('plan_$planId'),
      title: 'Plan reminder',
      body: title,
      scheduled: scheduled,
      details: NotificationDetails(
        android: const AndroidNotificationDetails(
          'plan_reminders',
          'Plan reminders',
          channelDescription: 'Reminders for plans and tasks',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(subtitle: body),
      ),
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

    await _zonedSchedule(
      id: _notificationId('sub_$subscriptionId'),
      title: 'Bill reminder',
      body: title,
      scheduled: scheduled,
      details: NotificationDetails(
        android: const AndroidNotificationDetails(
          'subscription_reminders',
          'Subscription reminders',
          channelDescription: 'Reminders for recurring bills and subscriptions',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(subtitle: body),
      ),
    );
  }

  Future<void> cancelSubscriptionReminder(String subscriptionId) async {
    await _plugin.cancel(_notificationId('sub_$subscriptionId'));
  }

  static const _maxMedicineTimeSlots = 12;

  Future<void> scheduleMedicineReminder({
    required String scheduleId,
    required int timeIndex,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _zonedSchedule(
      id: _notificationId('med_${scheduleId}_$timeIndex'),
      title: 'Medicine reminder',
      body: title,
      scheduled: scheduled,
      details: NotificationDetails(
        android: const AndroidNotificationDetails(
          'medicine_reminders',
          'Medicine reminders',
          channelDescription: 'Daily medicine schedule reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(subtitle: body),
      ),
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelMedicineReminders(String scheduleId) async {
    for (var i = 0; i < _maxMedicineTimeSlots; i++) {
      await _plugin.cancel(_notificationId('med_${scheduleId}_$i'));
    }
  }

  Future<void> scheduleStandaloneReminder({
    required String reminderId,
    required String title,
    required String body,
    required DateTime reminderAt,
  }) async {
    final scheduled = tz.TZDateTime.from(reminderAt.toLocal(), tz.local);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _zonedSchedule(
      id: _notificationId('rem_$reminderId'),
      title: 'Reminder',
      body: title,
      scheduled: scheduled,
      details: NotificationDetails(
        android: const AndroidNotificationDetails(
          'standalone_reminders',
          'Reminders',
          channelDescription: 'General reminders you create in MyPlanr',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(subtitle: body),
      ),
    );
  }

  Future<void> cancelStandaloneReminder(String reminderId) async {
    await _plugin.cancel(_notificationId('rem_$reminderId'));
  }
}
