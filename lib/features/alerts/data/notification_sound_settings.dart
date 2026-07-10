import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_alert_type.dart';

class NotificationSoundPreference {
  const NotificationSoundPreference({this.uri, this.title});

  final String? uri;
  final String? title;

  bool get usesDeviceDefault => uri == null || uri!.isEmpty;

  String displayLabel(String defaultLabel) =>
      usesDeviceDefault ? defaultLabel : (title ?? defaultLabel);
}

class NotificationSoundSettings {
  NotificationSoundSettings(this._prefs);

  final SharedPreferences _prefs;

  static Future<NotificationSoundSettings> load() async {
    return NotificationSoundSettings(await SharedPreferences.getInstance());
  }

  static String _uriKey(NotificationAlertType type) =>
      'notification_sound_uri_${type.id}';

  static String _titleKey(NotificationAlertType type) =>
      'notification_sound_title_${type.id}';

  NotificationSoundPreference preference(NotificationAlertType type) {
    return NotificationSoundPreference(
      uri: _prefs.getString(_uriKey(type)),
      title: _prefs.getString(_titleKey(type)),
    );
  }

  Map<NotificationAlertType, NotificationSoundPreference> allPreferences() {
    return {
      for (final type in NotificationAlertType.settingsTypes)
        type: preference(type),
    };
  }

  Future<void> setPreference(
    NotificationAlertType type, {
    String? uri,
    String? title,
  }) async {
    final uriKey = _uriKey(type);
    final titleKey = _titleKey(type);
    if (uri == null || uri.isEmpty) {
      await _prefs.remove(uriKey);
      await _prefs.remove(titleKey);
      return;
    }
    await _prefs.setString(uriKey, uri);
    if (title != null && title.isNotEmpty) {
      await _prefs.setString(titleKey, title);
    } else {
      await _prefs.remove(titleKey);
    }
  }

  /// Android channels are immutable; include sound identity in the channel id.
  static String androidChannelId(
    NotificationAlertType type,
    NotificationSoundPreference preference,
  ) {
    final uri = preference.uri;
    if (uri == null || uri.isEmpty) return type.id;
    final suffix = uri.hashCode.abs().toRadixString(36);
    return '${type.id}_$suffix';
  }
}

class NotificationSoundPreferencesNotifier
    extends StateNotifier<AsyncValue<Map<NotificationAlertType, NotificationSoundPreference>>> {
  NotificationSoundPreferencesNotifier() : super(const AsyncValue.loading()) {
    reload();
  }

  NotificationSoundSettings? _settings;

  Future<void> reload() async {
    state = const AsyncValue.loading();
    try {
      _settings = await NotificationSoundSettings.load();
      state = AsyncValue.data(_settings!.allPreferences());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setPreference(
    NotificationAlertType type, {
    String? uri,
    String? title,
  }) async {
    final settings = _settings ?? await NotificationSoundSettings.load();
    _settings = settings;
    await settings.setPreference(type, uri: uri, title: title);
    state = AsyncValue.data(settings.allPreferences());
  }

  Future<void> resetToDefault(NotificationAlertType type) {
    return setPreference(type);
  }
}

final notificationSoundPreferencesProvider = StateNotifierProvider<
    NotificationSoundPreferencesNotifier,
    AsyncValue<Map<NotificationAlertType, NotificationSoundPreference>>>(
  (ref) => NotificationSoundPreferencesNotifier(),
);
