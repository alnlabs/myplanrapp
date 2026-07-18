import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/logging/app_logger.dart';
import '../../../shared/constants/reminder_repeat.dart';
import '../data/notification_alert_type.dart';
import '../data/notification_sound_settings.dart';

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

  Future<NotificationDetails> _detailsFor(
    NotificationAlertType alertType, {
    required Importance importance,
    required Priority priority,
    String? iosSubtitle,
  }) async {
    final settings = await NotificationSoundSettings.load();
    final soundPreference = settings.preference(alertType);
    final channelId = NotificationSoundSettings.androidChannelId(
      alertType,
      soundPreference,
    );

    AndroidNotificationSound? androidSound;
    final uri = soundPreference.uri;
    if (uri != null && uri.isNotEmpty) {
      androidSound = UriAndroidNotificationSound(uri);
    }

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        alertType.channelName,
        channelDescription: alertType.channelDescription,
        importance: importance,
        priority: priority,
        sound: androidSound,
      ),
      iOS: DarwinNotificationDetails(subtitle: iosSubtitle),
    );
  }

  Future<void> showLowStockAlert({
    required String itemId,
    required String title,
    required String body,
  }) async {
    if (!await _notificationsAllowed()) return;
    final details = await _detailsFor(
      NotificationAlertType.lowStock,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    await _plugin.show(_notificationId(itemId), title, body, details);
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
      details: await _detailsFor(
        NotificationAlertType.planReminders,
        importance: Importance.high,
        priority: Priority.high,
        iosSubtitle: body,
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
      details: await _detailsFor(
        NotificationAlertType.subscriptionReminders,
        importance: Importance.high,
        priority: Priority.high,
        iosSubtitle: body,
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
      details: await _detailsFor(
        NotificationAlertType.medicineReminders,
        importance: Importance.high,
        priority: Priority.high,
        iosSubtitle: body,
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
    String repeat = ReminderRepeat.none,
  }) async {
    final recurring = ReminderRepeat.isRecurring(repeat);
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime.from(reminderAt.toLocal(), tz.local);
    if (scheduled.isBefore(now)) {
      // One-time reminders in the past are dropped; recurring ones roll forward
      // to their next occurrence so the OS has a valid future anchor.
      if (!recurring) return;
      scheduled = _advanceToFuture(scheduled, now, repeat);
    }

    await _zonedSchedule(
      id: _notificationId('rem_$reminderId'),
      title: 'Reminder',
      body: title,
      scheduled: scheduled,
      details: await _detailsFor(
        NotificationAlertType.standaloneReminders,
        importance: Importance.high,
        priority: Priority.high,
        iosSubtitle: body,
      ),
      matchDateTimeComponents: _repeatComponents(repeat),
    );
  }

  DateTimeComponents? _repeatComponents(String repeat) => switch (repeat) {
        ReminderRepeat.daily => DateTimeComponents.time,
        ReminderRepeat.weekly => DateTimeComponents.dayOfWeekAndTime,
        ReminderRepeat.monthly => DateTimeComponents.dayOfMonthAndTime,
        ReminderRepeat.yearly => DateTimeComponents.dateAndTime,
        _ => null,
      };

  tz.TZDateTime _advanceToFuture(
    tz.TZDateTime start,
    tz.TZDateTime now,
    String repeat,
  ) {
    var next = start;
    var guard = 0;
    while (!next.isAfter(now) && guard < 1000) {
      next = switch (repeat) {
        ReminderRepeat.daily => next.add(const Duration(days: 1)),
        ReminderRepeat.weekly => next.add(const Duration(days: 7)),
        ReminderRepeat.monthly => tz.TZDateTime(
            tz.local, next.year, next.month + 1, next.day, next.hour,
            next.minute),
        ReminderRepeat.yearly => tz.TZDateTime(
            tz.local, next.year + 1, next.month, next.day, next.hour,
            next.minute),
        _ => next.add(const Duration(days: 1)),
      };
      guard++;
    }
    return next;
  }

  Future<void> cancelStandaloneReminder(String reminderId) async {
    await _plugin.cancel(_notificationId('rem_$reminderId'));
  }

  /// Plays a one-shot preview using the saved sound for [alertType].
  Future<bool> previewAlertSound(NotificationAlertType alertType) async {
    if (!await _notificationsAllowed()) return false;
    if (!_initialized) await initialize();

    final android = _android;
    if (android != null) {
      final granted = await android.areNotificationsEnabled();
      if (granted != true) return false;
    }

    final details = await _detailsFor(
      alertType,
      importance: Importance.high,
      priority: Priority.high,
    );
    await _plugin.show(
      _notificationId('preview_${alertType.id}'),
      alertType.previewTitle,
      alertType.previewBody,
      details,
    );
    return true;
  }

  /// Immediate notification to verify device alerts are working.
  Future<bool> showTestAlert() async {
    if (!await _notificationsAllowed()) return false;
    if (!_initialized) await initialize();

    final android = _android;
    if (android != null) {
      final granted = await android.areNotificationsEnabled();
      if (granted != true) return false;
    }

    final details = await _detailsFor(
      NotificationAlertType.testAlerts,
      importance: Importance.high,
      priority: Priority.high,
    );
    await _plugin.show(
      _notificationId('test_alert'),
      NotificationAlertType.testAlerts.previewTitle,
      'If you see this, device reminders are working on this phone.',
      details,
    );
    return true;
  }
}
