import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/assets/presentation/service_record_form_screen.dart';
import 'package:myplanr/shared/constants/asset_constants.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('ServiceRecordFormScreen widget', () {
    testWidgets('requires shop name for shop repair type', (tester) async {
      await pumpTestApp(
        tester,
        child: const ServiceRecordFormScreen(
          assetId: 'asset-1',
          householdId: testHouseholdId,
        ),
      );

      await tapSave(tester);
      expect(find.text(AppStrings.requiredField), findsOneWidget);
    });

    testWidgets('rejects invalid optional cost', (tester) async {
      await pumpTestApp(
        tester,
        child: const ServiceRecordFormScreen(
          assetId: 'asset-1',
          householdId: testHouseholdId,
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, AppStrings.shopName),
        'Repair Hub',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, AppStrings.serviceCost),
        '-10',
      );
      await tester.pumpAndSettle();
      await tapSave(tester);

      expect(find.text(AppStrings.invalidAmount), findsOneWidget);
    });

    testWidgets('third-party type hides shop name requirement', (tester) async {
      await pumpTestApp(
        tester,
        child: const ServiceRecordFormScreen(
          assetId: 'asset-1',
          householdId: testHouseholdId,
        ),
      );

      await tester.tap(find.text(AppStrings.serviceType));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Third-party service').last);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.shopName), findsNothing);
      expect(find.text(AppStrings.platformName), findsOneWidget);
    });
  });
}
