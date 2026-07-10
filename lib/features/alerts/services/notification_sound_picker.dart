import 'dart:io';

import 'package:flutter/services.dart';

class NotificationSoundPickResult {
  const NotificationSoundPickResult({this.uri, this.title});

  final String? uri;
  final String? title;

  bool get cancelled => uri == null;
}

/// Opens the Android system notification sound picker.
class NotificationSoundPicker {
  NotificationSoundPicker._();

  static const _channel = MethodChannel('com.alnlabs.myplanr/notification_sounds');

  static bool get isSupported => Platform.isAndroid;

  static Future<NotificationSoundPickResult> pick({
    String? currentUri,
  }) async {
    if (!isSupported) return const NotificationSoundPickResult();

    final result = await _channel.invokeMethod<Object?>(
      'pickNotificationSound',
      {'currentUri': currentUri},
    );

    if (result == null) return const NotificationSoundPickResult();

    if (result is! Map) return const NotificationSoundPickResult();
    final map = Map<Object?, Object?>.from(result);
    final uri = map['uri'] as String?;
    final title = map['title'] as String?;
    if (uri == null || uri.isEmpty) return const NotificationSoundPickResult();
    return NotificationSoundPickResult(uri: uri, title: title);
  }

  static Future<String?> ringtoneTitle(String uri) async {
    if (!isSupported || uri.isEmpty) return null;
    return _channel.invokeMethod<String>('getRingtoneTitle', {'uri': uri});
  }
}
