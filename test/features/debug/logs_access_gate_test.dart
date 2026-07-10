import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/debug/logs_access_gate.dart';

import '../../helpers/pump_app.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: '');
  });

  group('LogsAccessGate', () {
    testWidgets('shows not-configured snackbar when pin unset', (tester) async {
      await pumpTestApp(
        tester,
        child: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => LogsAccessGate.openIfAuthorized(context),
              child: const Text('Open logs'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open logs'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(AppStrings.logsPinNotConfigured), findsOneWidget);
    });
  });
}
