import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/constants/household_modules.dart';

void main() {
  group('HouseholdInterests.modulesFromInterests', () {
    test('maps groceries to pantry and shopping', () {
      final modules = HouseholdInterests.modulesFromInterests({
        HouseholdInterests.groceries,
      });
      expect(modules, contains(HouseholdModules.pantry));
      expect(modules, contains(HouseholdModules.shopping));
    });

    test('maps bills to subscriptions, expenses, reminders', () {
      final modules = HouseholdInterests.modulesFromInterests({
        HouseholdInterests.bills,
      });
      expect(modules, contains(HouseholdModules.subscriptions));
      expect(modules, contains(HouseholdModules.expenses));
      expect(modules, contains(HouseholdModules.reminders));
    });

    test('returns defaults when interests empty', () {
      final modules = HouseholdInterests.modulesFromInterests({});
      expect(modules, HouseholdModules.defaultEnabled.toSet());
    });

    test('combines multiple interests', () {
      final modules = HouseholdInterests.modulesFromInterests({
        HouseholdInterests.expenses,
        HouseholdInterests.assets,
      });
      expect(modules, contains(HouseholdModules.expenses));
      expect(modules, contains(HouseholdModules.assets));
    });
  });
}
