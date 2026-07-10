import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/constants/household_modules.dart';
import 'package:myplanr/shared/constants/nav_features.dart';

void main() {
  final allModules = HouseholdModules.defaultEnabled.toSet()
    ..add(HouseholdModules.subscriptions);

  group('NavFeatures.enabled', () {
    test('includes enabled modules only', () {
      final enabled = NavFeatures.enabled({HouseholdModules.pantry});
      expect(enabled, hasLength(1));
      expect(enabled.single.module, HouseholdModules.pantry);
    });

    test('shows plans when reminders enabled without plans module', () {
      final enabled = NavFeatures.enabled({HouseholdModules.reminders});
      expect(
        enabled.any((f) => f.module == HouseholdModules.plans),
        isTrue,
      );
    });
  });

  group('NavFeatures.showMoreTab', () {
    test('false when few modules enabled', () {
      expect(
        NavFeatures.showMoreTab({HouseholdModules.pantry}),
        isFalse,
      );
    });

    test('true when more than 3 feature modules', () {
      expect(NavFeatures.showMoreTab(allModules), isTrue);
    });
  });

  group('NavFeatures.bottomBarFeatures', () {
    test('returns all when they fit', () {
      final bar = NavFeatures.bottomBarFeatures({HouseholdModules.pantry});
      expect(bar, hasLength(1));
    });

    test('truncates when overflow requires More tab', () {
      final bar = NavFeatures.bottomBarFeatures(allModules);
      expect(bar.length, lessThan(NavFeatures.enabled(allModules).length));
    });
  });

  group('NavFeatures.overflowFeatures', () {
    test('empty when no overflow', () {
      expect(
        NavFeatures.overflowFeatures({HouseholdModules.pantry}),
        isEmpty,
      );
    });

    test('non-empty when More tab shown', () {
      final overflow = NavFeatures.overflowFeatures(allModules);
      expect(overflow, isNotEmpty);
    });
  });
}
