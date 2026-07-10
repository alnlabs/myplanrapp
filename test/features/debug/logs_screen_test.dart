import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/logging/app_logger.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/debug/presentation/logs_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  tearDown(() {
    AppLogger.instance.entries.value = [];
  });

  group('LogsScreen widget', () {
    testWidgets('shows empty state when no logs', (tester) async {
      AppLogger.instance.entries.value = [];

      await pumpTestApp(tester, child: const LogsScreen());

      expect(find.text(AppStrings.logsTitle), findsOneWidget);
      expect(find.text(AppStrings.logsEmpty), findsOneWidget);
    });

    testWidgets('renders log entries newest first', (tester) async {
      AppLogger.instance.entries.value = [
        LogEntry(
          time: DateTime(2025, 1, 1, 9, 0),
          level: LogLevel.info,
          message: 'Older entry',
        ),
        LogEntry(
          time: DateTime(2025, 1, 1, 10, 0),
          level: LogLevel.error,
          message: 'Newer entry',
          error: 'boom',
        ),
      ];

      await pumpTestApp(tester, child: const LogsScreen());

      expect(find.text('Newer entry'), findsOneWidget);
      expect(find.text('Older entry'), findsOneWidget);
      expect(find.text('ERROR'), findsOneWidget);
      expect(find.text('boom'), findsOneWidget);
    });

    testWidgets('clears logs after confirmation', (tester) async {
      AppLogger.instance.entries.value = [
        LogEntry(
          time: DateTime(2025, 1, 1, 10, 0),
          level: LogLevel.warning,
          message: 'Will be cleared',
        ),
      ];

      await pumpTestApp(tester, child: const LogsScreen());

      await tester.tap(find.byTooltip(AppStrings.logsClear));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, AppStrings.delete));
      await tester.pumpAndSettle();

      expect(AppLogger.instance.entries.value, isEmpty);
      expect(find.text(AppStrings.logsEmpty), findsOneWidget);
    });
  });
}
