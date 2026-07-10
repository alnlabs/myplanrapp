import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/home/presentation/more_screen.dart';
import 'package:myplanr/features/household/data/household_settings_repository.dart';
import 'package:myplanr/shared/constants/household_modules.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('MoreScreen widget', () {
    testWidgets('renders household, settings, and feedback tiles', (tester) async {
      await pumpShellTestApp(
        tester,
        overrides: [
          enabledModulesProvider.overrideWithValue(
            HouseholdModules.sanitizeEnabled(HouseholdModules.defaultEnabled),
          ),
        ],
        child: const MoreScreen(),
      );

      expect(find.text(AppStrings.navMore), findsOneWidget);
      expect(find.text(AppStrings.householdTitle), findsOneWidget);
      expect(find.text(AppStrings.settingsTitle), findsOneWidget);
      expect(find.text(AppStrings.feedbackTitle), findsOneWidget);
    });
  });
}
