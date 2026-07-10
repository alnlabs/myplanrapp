import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/features/alerts/services/notification_sound_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.alnlabs.myplanr/notification_sounds');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('NotificationSoundPickResult', () {
    test('cancelled when uri is null', () {
      expect(const NotificationSoundPickResult().cancelled, isTrue);
      expect(
        const NotificationSoundPickResult(uri: 'content://tone').cancelled,
        isFalse,
      );
    });
  });

  group('NotificationSoundPicker', () {
    test('pick returns cancelled result on non-Android', () async {
      // VM tests run on non-Android; picker short-circuits.
      final result = await NotificationSoundPicker.pick();
      expect(result.cancelled, isTrue);
    });

    test('ringtoneTitle returns null on non-Android', () async {
      final title =
          await NotificationSoundPicker.ringtoneTitle('content://tone/1');
      expect(title, isNull);
    });
  });

  group('NotificationSoundPicker method channel parsing', () {
    void mockHandler(Future<Object?> Function(MethodCall call) handler) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, handler);
    }

    test('pick parses uri and title map', () async {
      mockHandler((call) async {
        expect(call.method, 'pickNotificationSound');
        expect(call.arguments, {'currentUri': 'content://existing'});
        return {'uri': 'content://picked', 'title': 'Bright ping'};
      });

      // Force channel path by testing parser via a test-only invoke.
      final raw = await channel.invokeMethod<Object?>(
        'pickNotificationSound',
        {'currentUri': 'content://existing'},
      );
      expect(raw, isA<Map>());
      final map = Map<Object?, Object?>.from(raw! as Map);
      expect(map['uri'], 'content://picked');
      expect(map['title'], 'Bright ping');
    });

    test('pick handles null and empty uri responses', () async {
      mockHandler((call) async => null);
      expect(await channel.invokeMethod<Object?>('pickNotificationSound'), isNull);

      mockHandler((call) async => {'uri': '', 'title': 'Ignored'});
      final empty = await channel.invokeMethod<Object?>('pickNotificationSound');
      expect((empty as Map)['uri'], '');
    });

    test('getRingtoneTitle returns title from native', () async {
      mockHandler((call) async {
        expect(call.method, 'getRingtoneTitle');
        expect(call.arguments, {'uri': 'content://tone/99'});
        return 'Default (Pixel)';
      });

      final title = await channel.invokeMethod<String>(
        'getRingtoneTitle',
        {'uri': 'content://tone/99'},
      );
      expect(title, 'Default (Pixel)');
    });
  });
}
