import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/alerts/presentation/alerts_screen.dart';
import 'package:myplanr/features/pantry/data/pantry_repository.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('AlertsScreen widget', () {
    testWidgets('renders low stock pantry items', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          lowStockItemsProvider.overrideWith(
            (ref) async => [testLowStockPantryItem],
          ),
        ],
        child: const AlertsScreen(),
      );

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text(AppStrings.alertsTitle),
        ),
        findsOneWidget,
      );
      expect(find.text('Olive oil'), findsOneWidget);
      expect(find.textContaining(AppStrings.lowStockAlert), findsOneWidget);
    });

    testWidgets('shows empty state when no alerts', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          lowStockItemsProvider.overrideWith((ref) async => []),
        ],
        child: const AlertsScreen(),
      );

      expect(find.text(AppStrings.emptyAlerts), findsOneWidget);
      expect(find.text(AppStrings.emptyAlertsHint), findsOneWidget);
    });
  });
}
