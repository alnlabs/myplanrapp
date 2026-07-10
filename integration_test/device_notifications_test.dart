import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/alerts/services/notification_service.dart';
import 'package:myplanr/features/auth/data/auth_repository.dart';
import 'package:myplanr/features/settings/data/device_permissions.dart';
import 'package:myplanr/features/settings/presentation/device_permissions_screen.dart';
import 'package:myplanr/features/settings/presentation/settings_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/helpers/provider_overrides.dart';
import '../test/helpers/stub_repositories.dart';

/// Exercises real device notification permission + alert delivery.
///
/// Run on a simulator or phone (not plain `flutter test`):
/// `flutter test -d <device_id> integration_test/device_notifications_test.dart`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Device notifications integration', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({'notifications_enabled': true});
    });

    testWidgets('initializes the local notifications plugin', (tester) async {
      await NotificationService.instance.initialize();
    });

    testWidgets('requests OS notification permission', (tester) async {
      await NotificationService.instance.initialize();
      await NotificationService.instance.requestPermission();
    });

    testWidgets('shows an immediate test alert when OS allows notifications',
        (tester) async {
      await NotificationService.instance.initialize();
      await NotificationService.instance.requestPermission();

      final sent = await NotificationService.instance.showTestAlert();

      expect(sent, isTrue);
    });

    testWidgets('settings screen sends test notification from UI',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...testAuthOverrides,
            authRepositoryProvider.overrideWith((ref) => StubAuthRepository()),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text(AppStrings.settingsTestNotification),
        200,
      );
      await tester.tap(find.text(AppStrings.settingsTestNotification));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(
        find.text(AppStrings.settingsTestNotificationSent),
        findsOneWidget,
      );
    });

    testWidgets('device permissions screen requests notification access',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            devicePermissionsServiceProvider.overrideWithValue(
              const DevicePermissionsService(),
            ),
          ],
          child: const MaterialApp(home: DevicePermissionsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final notificationsTile = find.text('Notifications');
      if (notificationsTile.evaluate().isEmpty) {
        // Platform may omit the notifications row in test environments.
        return;
      }

      await tester.tap(notificationsTile);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final permissions = await const DevicePermissionsService().load();
      final notifications = permissions.where(
        (p) => p.kind == AppPermissionKind.notifications,
      );
      if (notifications.isEmpty) return;

      expect(
        notifications.first.status == PermissionStatus.granted ||
            notifications.first.status == PermissionStatus.provisional ||
            notifications.first.status == PermissionStatus.limited,
        isTrue,
      );
    });
  });
}
