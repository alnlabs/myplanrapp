import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/household/data/household_settings_repository.dart';
import 'package:myplanr/features/household/presentation/household_features_screen.dart';
import 'package:myplanr/shared/constants/household_modules.dart';
import 'package:myplanr/shared/widgets/loading_button.dart';

import '../../helpers/provider_overrides.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/stub_repositories.dart';

void main() {
  group('HouseholdFeaturesScreen widget', () {
    testWidgets('renders interest cards from enabled modules', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          ...testAuthOverrides,
          enabledModulesProvider.overrideWith(
            (ref) => {
              HouseholdModules.pantry,
              HouseholdModules.shopping,
              HouseholdModules.expenses,
            },
          ),
        ],
        child: const HouseholdFeaturesScreen(),
      );

      expect(find.text(AppStrings.featureSettings), findsOneWidget);
      expect(find.text(AppStrings.interestsQuestion), findsOneWidget);
      expect(find.text('Groceries & pantry'), findsOneWidget);
      expect(find.text('Household expenses'), findsOneWidget);
    });

    testWidgets('saves selected features', (tester) async {
      final settingsRepo = StubHouseholdSettingsRepository();

      await pumpTestApp(
        tester,
        overrides: [
          ...testAuthOverrides,
          enabledModulesProvider.overrideWith(
            (ref) => {HouseholdModules.pantry, HouseholdModules.shopping},
          ),
          householdSettingsRepositoryProvider.overrideWith((ref) => settingsRepo),
        ],
        child: const HouseholdFeaturesScreen(),
      );

      await tester.scrollUntilVisible(
        find.widgetWithText(LoadingButton, AppStrings.save),
        200,
      );
      await tester.tap(find.widgetWithText(LoadingButton, AppStrings.save));
      await tester.pumpAndSettle();

      expect(settingsRepo.lastUpdatedModules, isNotNull);
      expect(
        settingsRepo.lastUpdatedModules,
        containsAll([HouseholdModules.pantry, HouseholdModules.shopping]),
      );
    });
  });
}
