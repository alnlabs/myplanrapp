import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/home/utils/dashboard_greeting.dart';

void main() {
  group('dashboardGreetingForHour', () {
    test('morning before noon', () {
      expect(dashboardGreetingForHour(0), AppStrings.goodMorning);
      expect(dashboardGreetingForHour(11), AppStrings.goodMorning);
    });

    test('afternoon before 5pm', () {
      expect(dashboardGreetingForHour(12), AppStrings.goodAfternoon);
      expect(dashboardGreetingForHour(16), AppStrings.goodAfternoon);
    });

    test('evening from 5pm', () {
      expect(dashboardGreetingForHour(17), AppStrings.goodEvening);
      expect(dashboardGreetingForHour(23), AppStrings.goodEvening);
    });
  });

  group('dashboardGreeting', () {
    test('uses provided time', () {
      expect(
        dashboardGreeting(DateTime(2026, 7, 10, 8)),
        AppStrings.goodMorning,
      );
    });
  });
}
