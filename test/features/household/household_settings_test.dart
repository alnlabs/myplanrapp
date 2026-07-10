import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/features/household/data/household_settings_repository.dart';
import 'package:myplanr/shared/constants/household_modules.dart';

void main() {
  group('HouseholdSettings', () {
    test('isEnabled checks module list', () {
      const settings = HouseholdSettings(
        householdId: 'hh',
        enabledModules: [HouseholdModules.pantry, HouseholdModules.expenses],
      );
      expect(settings.isEnabled(HouseholdModules.pantry), isTrue);
      expect(settings.isEnabled(HouseholdModules.plans), isFalse);
    });

    test('fromJson uses defaults when modules missing', () {
      final settings = HouseholdSettings.fromJson({
        'household_id': 'hh',
      });
      expect(settings.enabledModules, HouseholdModules.defaultEnabled);
    });

    test('fromJson reads module list', () {
      final settings = HouseholdSettings.fromJson({
        'household_id': 'hh',
        'enabled_modules': [HouseholdModules.pantry],
      });
      expect(settings.enabledModules, [HouseholdModules.pantry]);
    });
  });
}
