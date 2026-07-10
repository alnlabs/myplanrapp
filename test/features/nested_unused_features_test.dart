import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/constants/household_modules.dart';

void main() {
  group('HouseholdModules.sanitizeEnabled', () {
    test('removes deprecated recipes module from stored settings', () {
      final sanitized = HouseholdModules.sanitizeEnabled([
        HouseholdModules.pantry,
        HouseholdModules.recipes,
        HouseholdModules.expenses,
      ]);
      expect(sanitized, {HouseholdModules.pantry, HouseholdModules.expenses});
      expect(sanitized.contains(HouseholdModules.recipes), isFalse);
    });

    test('drops unknown module ids', () {
      final sanitized = HouseholdModules.sanitizeEnabled([
        HouseholdModules.plans,
        'unknown_module',
      ]);
      expect(sanitized, {HouseholdModules.plans});
    });

    test('returns empty when only deprecated modules stored', () {
      expect(
        HouseholdModules.sanitizeEnabled([HouseholdModules.recipes]),
        isEmpty,
      );
    });
  });

  group('HouseholdInterests.modulesFromInterests', () {
    test('maps groceries to pantry and shopping', () {
      final modules = HouseholdInterests.modulesFromInterests(
        {HouseholdInterests.groceries},
      );
      expect(modules, {
        HouseholdModules.pantry,
        HouseholdModules.shopping,
      });
    });

    test('maps bills to subscriptions, expenses, and reminders', () {
      final modules = HouseholdInterests.modulesFromInterests(
        {HouseholdInterests.bills},
      );
      expect(modules, {
        HouseholdModules.subscriptions,
        HouseholdModules.expenses,
        HouseholdModules.reminders,
      });
    });

    test('defaults to all active modules when interests empty', () {
      final modules = HouseholdInterests.modulesFromInterests({});
      expect(modules, HouseholdModules.defaultEnabled.toSet());
    });
  });
}
