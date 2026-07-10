import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/features/alerts/data/notification_alert_type.dart';
import 'package:myplanr/features/alerts/data/notification_sound_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('NotificationSoundPreference', () {
    test('displayLabel falls back when title missing but uri set', () {
      const preference = NotificationSoundPreference(uri: 'content://tone/1');
      expect(preference.usesDeviceDefault, isFalse);
      expect(
        preference.displayLabel('Device default'),
        'Device default',
      );
    });

    test('cancelled pick result has no uri', () {
      expect(const NotificationSoundPreference().usesDeviceDefault, isTrue);
    });
  });

  group('NotificationSoundSettings.androidChannelId', () {
    test('uses base id for device default', () {
      const preference = NotificationSoundPreference();
      expect(
        NotificationSoundSettings.androidChannelId(
          NotificationAlertType.planReminders,
          preference,
        ),
        'plan_reminders',
      );
    });

    test('appends stable suffix for custom uri', () {
      const preference = NotificationSoundPreference(
        uri: 'content://media/internal/audio/media/42',
        title: 'Ping',
      );
      final channelId = NotificationSoundSettings.androidChannelId(
        NotificationAlertType.medicineReminders,
        preference,
      );
      expect(channelId.startsWith('medicine_reminders_'), isTrue);
      expect(channelId.length, greaterThan('medicine_reminders_'.length));
    });

    test('covers every alert type with custom uri', () {
      const preference = NotificationSoundPreference(
        uri: 'content://media/internal/audio/media/99',
      );
      for (final type in NotificationAlertType.settingsTypes) {
        final channelId = NotificationSoundSettings.androidChannelId(
          type,
          preference,
        );
        expect(channelId.startsWith('${type.id}_'), isTrue);
      }
    });
  });

  group('NotificationSoundSettings persistence', () {
    test('stores and clears uri and title', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = await NotificationSoundSettings.load();

      await settings.setPreference(
        NotificationAlertType.lowStock,
        uri: 'content://tone/1',
        title: 'Chime',
      );

      var preference = settings.preference(NotificationAlertType.lowStock);
      expect(preference.uri, 'content://tone/1');
      expect(preference.title, 'Chime');
      expect(preference.usesDeviceDefault, isFalse);
      expect(
        preference.displayLabel('Device default'),
        'Chime',
      );

      await settings.resetToDefault(NotificationAlertType.lowStock);
      preference = settings.preference(NotificationAlertType.lowStock);
      expect(preference.usesDeviceDefault, isTrue);
      expect(
        preference.displayLabel('Device default'),
        'Device default',
      );
    });

    test('allPreferences returns entry for each alert type', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = await NotificationSoundSettings.load();
      final all = settings.allPreferences();

      expect(all.length, NotificationAlertType.settingsTypes.length);
      for (final type in NotificationAlertType.settingsTypes) {
        expect(all.containsKey(type), isTrue);
        expect(all[type]!.usesDeviceDefault, isTrue);
      }
    });

    test('stores uri without title when title omitted', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = await NotificationSoundSettings.load();

      await settings.setPreference(
        NotificationAlertType.testAlerts,
        uri: 'content://tone/test',
      );

      final preference = settings.preference(NotificationAlertType.testAlerts);
      expect(preference.uri, 'content://tone/test');
      expect(preference.title, isNull);
    });

    test('each alert type uses independent preference keys', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = await NotificationSoundSettings.load();

      for (final type in NotificationAlertType.settingsTypes) {
        await settings.setPreference(
          type,
          uri: 'content://tone/${type.id}',
          title: 'Tone ${type.id}',
        );
      }

      for (final type in NotificationAlertType.settingsTypes) {
        final preference = settings.preference(type);
        expect(preference.uri, 'content://tone/${type.id}');
        expect(preference.title, 'Tone ${type.id}');
      }
    });
  });

  group('NotificationSoundPreferencesNotifier', () {
    test('setPreference and resetToDefault update state', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = NotificationSoundPreferencesNotifier();
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.hasValue, isTrue);

      await notifier.setPreference(
        NotificationAlertType.subscriptionReminders,
        uri: 'content://sub',
        title: 'Bill chime',
      );
      final updated = notifier.state.value!;
      expect(
        updated[NotificationAlertType.subscriptionReminders]!.title,
        'Bill chime',
      );

      await notifier.resetToDefault(NotificationAlertType.subscriptionReminders);
      final reset = notifier.state.value!;
      expect(
        reset[NotificationAlertType.subscriptionReminders]!.usesDeviceDefault,
        isTrue,
      );
    });
  });
}

extension on NotificationSoundSettings {
  Future<void> resetToDefault(NotificationAlertType type) {
    return setPreference(type);
  }
}
