import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/auth/data/auth_repository.dart';
import 'package:myplanr/features/settings/data/device_permissions.dart';
import 'package:myplanr/features/settings/presentation/device_permissions_screen.dart';
import 'package:myplanr/features/settings/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/provider_overrides.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/stub_repositories.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsScreen behavior', () {
    testWidgets('theme dialog switches to dark mode', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          ...testAuthOverrides,
          authRepositoryProvider.overrideWith((ref) => StubAuthRepository()),
        ],
        child: const SettingsScreen(),
      );

      await tester.tap(find.text(AppStrings.settingsTheme));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.settingsThemeDark));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.settingsThemeDark), findsWidgets);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');
    });

    testWidgets('notification switch persists disabled state', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          ...testAuthOverrides,
          authRepositoryProvider.overrideWith((ref) => StubAuthRepository()),
        ],
        child: const SettingsScreen(),
      );

      final switchTile = find.byType(SwitchListTile);
      expect(tester.widget<SwitchListTile>(switchTile).value, isTrue);

      await tester.tap(switchTile);
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(switchTile).value, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notifications_enabled'), isFalse);
    });

    testWidgets('navigates to device permissions screen', (tester) async {
      final service = StubDevicePermissionsService(
        permissions: testDevicePermissions(),
      );

      await pumpTestApp(
        tester,
        overrides: [
          ...testAuthOverrides,
          authRepositoryProvider.overrideWith((ref) => StubAuthRepository()),
          devicePermissionsServiceProvider.overrideWithValue(service),
        ],
        child: const SettingsScreen(),
      );

      await tester.scrollUntilVisible(
        find.text(AppStrings.settingsPermissions),
        200,
      );
      await tester.tap(find.text(AppStrings.settingsPermissions));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(DevicePermissionsScreen), findsOneWidget);
    });

    testWidgets('delete account dialog cancel keeps user on settings', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          ...testAuthOverrides,
          authRepositoryProvider.overrideWith((ref) => StubAuthRepository()),
        ],
        child: const SettingsScreen(),
      );

      await tester.scrollUntilVisible(find.text(AppStrings.deleteAccount), 200);
      await tester.tap(find.text(AppStrings.deleteAccount));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.cancel));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.settingsTitle), findsOneWidget);
    });
  });
}
