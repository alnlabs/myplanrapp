import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/features/settings/data/device_permissions.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  group('AppPermissionInfo', () {
    test('isGranted for granted statuses', () {
      const granted = AppPermissionInfo(
        kind: AppPermissionKind.notifications,
        title: 'Notifications',
        reason: 'Needed',
        status: PermissionStatus.granted,
      );
      expect(granted.isGranted, isTrue);
      expect(granted.isPermanentlyDenied, isFalse);
    });

    test('isGranted for limited and provisional', () {
      const limited = AppPermissionInfo(
        kind: AppPermissionKind.photos,
        title: 'Photos',
        reason: 'Needed',
        status: PermissionStatus.limited,
      );
      expect(limited.isGranted, isTrue);

      const provisional = AppPermissionInfo(
        kind: AppPermissionKind.notifications,
        title: 'Notifications',
        reason: 'Needed',
        status: PermissionStatus.provisional,
      );
      expect(provisional.isGranted, isTrue);
    });

    test('isPermanentlyDenied for denied and restricted', () {
      const denied = AppPermissionInfo(
        kind: AppPermissionKind.camera,
        title: 'Camera',
        reason: 'Needed',
        status: PermissionStatus.permanentlyDenied,
      );
      expect(denied.isPermanentlyDenied, isTrue);
      expect(denied.isGranted, isFalse);

      const restricted = AppPermissionInfo(
        kind: AppPermissionKind.camera,
        title: 'Camera',
        reason: 'Needed',
        status: PermissionStatus.restricted,
      );
      expect(restricted.isPermanentlyDenied, isTrue);
    });
  });
}
