import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/logging/app_logger.dart';

void main() {
  tearDown(() {
    AppLogger.instance.entries.value = [];
  });

  group('LogEntry', () {
    test('round-trips through json', () {
      final entry = LogEntry(
        time: DateTime(2025, 6, 1, 12, 30),
        level: LogLevel.warning,
        message: 'Something happened',
        error: 'details',
        stackTrace: 'stack',
      );

      final restored = LogEntry.fromJson(entry.toJson());

      expect(restored.message, entry.message);
      expect(restored.level, entry.level);
      expect(restored.error, entry.error);
      expect(restored.stackTrace, entry.stackTrace);
      expect(restored.time, entry.time);
    });

    test('format includes level, message, and error', () {
      final entry = LogEntry(
        time: DateTime(2025, 6, 1),
        level: LogLevel.error,
        message: 'Failed',
        error: 'timeout',
      );

      final formatted = entry.format();
      expect(formatted, contains('ERROR'));
      expect(formatted, contains('Failed'));
      expect(formatted, contains('timeout'));
    });
  });

  group('AppLogger', () {
    test('captures entries and exports text', () {
      AppLogger.instance.entries.value = [];
      AppLogger.instance.info('First');
      AppLogger.instance.error('Second', 'boom');

      expect(AppLogger.instance.entries.value, hasLength(2));
      expect(AppLogger.instance.exportText(), contains('First'));
      expect(AppLogger.instance.exportText(), contains('Second'));
    });

    test('clear removes all entries', () async {
      AppLogger.instance.info('Temporary');
      await AppLogger.instance.clear();

      expect(AppLogger.instance.entries.value, isEmpty);
      expect(AppLogger.instance.exportText(), 'No logs captured.');
    });
  });
}
