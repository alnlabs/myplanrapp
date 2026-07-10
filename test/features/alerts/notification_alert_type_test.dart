import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/features/alerts/data/notification_alert_type.dart';

void main() {
  group('NotificationAlertType', () {
    test('settingsTypes lists every alert category once', () {
      expect(
        NotificationAlertType.settingsTypes,
        NotificationAlertType.values,
      );
    });

    test('every type has unique id and non-empty metadata', () {
      final ids = <String>{};
      for (final type in NotificationAlertType.values) {
        expect(type.id, isNotEmpty);
        expect(type.channelName, isNotEmpty);
        expect(type.channelDescription, isNotEmpty);
        expect(type.settingsLabel, isNotEmpty);
        expect(type.previewTitle, isNotEmpty);
        expect(type.previewBody, isNotEmpty);
        expect(ids.add(type.id), isTrue, reason: 'duplicate id ${type.id}');
      }
    });
  });
}
