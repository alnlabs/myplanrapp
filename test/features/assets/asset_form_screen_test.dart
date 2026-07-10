import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/assets/presentation/asset_form_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('AssetFormScreen widget', () {
    testWidgets('requires asset name', (tester) async {
      await pumpTestApp(
        tester,
        child: const AssetFormScreen(),
      );

      await tapSave(tester);
      expect(find.text(AppStrings.requiredField), findsOneWidget);
    });

    testWidgets('prefills initial name', (tester) async {
      await pumpTestApp(
        tester,
        child: const AssetFormScreen(initialName: 'Washing machine'),
      );

      expect(find.text('Washing machine'), findsOneWidget);
    });

    testWidgets('description and location are optional', (tester) async {
      await pumpTestApp(
        tester,
        child: const AssetFormScreen(),
      );

      await tester.enterText(find.byType(TextFormField).at(1), 'Kitchen appliance');
      await tester.enterText(find.byType(TextFormField).at(2), 'Utility room');
      await tester.pumpAndSettle();

      expect(find.text('Kitchen appliance'), findsOneWidget);
      expect(find.text('Utility room'), findsOneWidget);
    });

    testWidgets('renders category and kind dropdowns', (tester) async {
      await pumpTestApp(
        tester,
        child: const AssetFormScreen(),
      );

      expect(find.text(AppStrings.assetCategory), findsOneWidget);
      expect(find.text(AppStrings.assetKind), findsOneWidget);
    });
  });
}
