import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/alerts/data/notification_alert_type.dart';
import 'package:myplanr/features/alerts/data/notification_sound_settings.dart';
import 'package:myplanr/features/alerts/services/notification_sound_picker.dart';
import 'package:myplanr/features/settings/presentation/notification_sounds_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/pump_app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'notification_sound_uri_plan_reminders': 'content://tone/plan',
      'notification_sound_title_plan_reminders': 'Soft bell',
    });
  });

  group('NotificationSoundsScreen widget', () {
    testWidgets('lists every alert type row', (tester) async {
      await pumpTestApp(
        tester,
        child: const NotificationSoundsScreen(),
      );

      for (final type in NotificationAlertType.settingsTypes) {
        expect(find.text(type.settingsLabel), findsOneWidget);
      }
      expect(
        find.text(AppStrings.notificationSoundsSystemSettings),
        findsOneWidget,
      );
    });

    testWidgets('lists alert types with saved sound labels', (tester) async {
      await pumpTestApp(
        tester,
        child: const NotificationSoundsScreen(),
      );

      expect(find.text(AppStrings.notificationSoundsTitle), findsOneWidget);
      expect(find.text('Soft bell'), findsOneWidget);
      expect(
        find.text(AppStrings.notificationSoundDeviceDefault),
        findsWidgets,
      );
    });

    testWidgets('reset button clears custom sound', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          notificationSoundPreferencesProvider.overrideWith(
            (ref) => _TestNotificationSoundPreferencesNotifier(),
          ),
        ],
        child: const NotificationSoundsScreen(),
      );

      await tester.tap(find.byIcon(Icons.restart_alt).first);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.notificationSoundReset), findsOneWidget);
    });

    testWidgets('pick sound saves preference and shows saved snackbar',
        (tester) async {
      final notifier = _TrackingNotificationSoundPreferencesNotifier();

      await pumpTestApp(
        tester,
        overrides: [
          notificationSoundPreferencesProvider.overrideWith((ref) => notifier),
        ],
        child: NotificationSoundsScreen(
          pickSound: ({currentUri}) async => const NotificationSoundPickResult(
            uri: 'content://tone/new',
            title: 'Chime',
          ),
          previewSound: (_) async => true,
        ),
      );

      await tester.tap(find.text(NotificationAlertType.planReminders.settingsLabel));
      await tester.pumpAndSettle();

      expect(notifier.lastSetType, NotificationAlertType.planReminders);
      expect(notifier.lastSetUri, 'content://tone/new');
      expect(notifier.lastSetTitle, 'Chime');
      expect(find.text(AppStrings.notificationSoundSaved), findsOneWidget);
      expect(find.text('Chime'), findsOneWidget);
    });

    testWidgets('cancelled pick does not update preferences', (tester) async {
      final notifier = _TrackingNotificationSoundPreferencesNotifier();

      await pumpTestApp(
        tester,
        overrides: [
          notificationSoundPreferencesProvider.overrideWith((ref) => notifier),
        ],
        child: NotificationSoundsScreen(
          pickSound: ({currentUri}) async => const NotificationSoundPickResult(),
          previewSound: (_) async => true,
        ),
      );

      await tester.tap(find.text(NotificationAlertType.lowStock.settingsLabel));
      await tester.pumpAndSettle();

      expect(notifier.setPreferenceCalls, 0);
      expect(find.text(AppStrings.notificationSoundSaved), findsNothing);
    });

    testWidgets('preview failure shows permission denied snackbar', (tester) async {
      await pumpTestApp(
        tester,
        child: NotificationSoundsScreen(
          pickSound: ({currentUri}) async => const NotificationSoundPickResult(
            uri: 'content://tone/fail',
            title: 'Alert',
          ),
          previewSound: (_) async => false,
        ),
      );

      await tester.tap(find.text(NotificationAlertType.testAlerts.settingsLabel));
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.settingsNotificationPermissionDenied),
        findsOneWidget,
      );
    });
  });
}

class _TestNotificationSoundPreferencesNotifier
    extends NotificationSoundPreferencesNotifier {
  @override
  Future<void> reload() async {
    final settings = await NotificationSoundSettings.load();
    state = AsyncValue.data({
      for (final type in NotificationAlertType.settingsTypes)
        type: settings.preference(type),
    });
  }
}

class _TrackingNotificationSoundPreferencesNotifier
    extends NotificationSoundPreferencesNotifier {
  NotificationAlertType? lastSetType;
  String? lastSetUri;
  String? lastSetTitle;
  var setPreferenceCalls = 0;

  @override
  Future<void> reload() async {
    final settings = await NotificationSoundSettings.load();
    state = AsyncValue.data({
      for (final type in NotificationAlertType.settingsTypes)
        type: settings.preference(type),
    });
  }

  @override
  Future<void> setPreference(
    NotificationAlertType type, {
    String? uri,
    String? title,
  }) async {
    setPreferenceCalls++;
    lastSetType = type;
    lastSetUri = uri;
    lastSetTitle = title;
    await super.setPreference(type, uri: uri, title: title);
  }
}
