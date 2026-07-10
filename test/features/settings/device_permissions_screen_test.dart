import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/settings/data/device_permissions.dart';
import 'package:myplanr/features/settings/presentation/device_permissions_screen.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/stub_repositories.dart';

void main() {
  group('DevicePermissionsScreen widget', () {
    testWidgets('renders permission tiles with status labels', (tester) async {
      final service = StubDevicePermissionsService(
        permissions: testDevicePermissions(
          notifications: PermissionStatus.denied,
          camera: PermissionStatus.granted,
        ),
      );

      await pumpTestApp(
        tester,
        overrides: [
          devicePermissionsServiceProvider.overrideWithValue(service),
        ],
        child: const DevicePermissionsScreen(),
      );

      expect(find.text(AppStrings.settingsPermissions), findsOneWidget);
      expect(find.text(AppStrings.settingsPermissionsHint), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text(AppStrings.permissionDisabled), findsOneWidget);
      expect(find.text(AppStrings.permissionEnabled), findsOneWidget);
    });

    testWidgets('requests permission when tapping disabled tile', (tester) async {
      final service = StubDevicePermissionsService(
        permissions: testDevicePermissions(
          camera: PermissionStatus.denied,
        ),
      );

      await pumpTestApp(
        tester,
        overrides: [
          devicePermissionsServiceProvider.overrideWithValue(service),
        ],
        child: const DevicePermissionsScreen(),
      );

      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();

      expect(service.lastRequested, AppPermissionKind.camera);
    });

    testWidgets('opens settings when tapping granted tile', (tester) async {
      final service = StubDevicePermissionsService(
        permissions: testDevicePermissions(camera: PermissionStatus.granted),
      );

      await pumpTestApp(
        tester,
        overrides: [
          devicePermissionsServiceProvider.overrideWithValue(service),
        ],
        child: const DevicePermissionsScreen(),
      );

      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();

      expect(service.settingsOpened, isTrue);
    });
  });
}
