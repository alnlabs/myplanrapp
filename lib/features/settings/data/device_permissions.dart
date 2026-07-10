import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// Device-level permissions the app relies on.
enum AppPermissionKind { notifications, exactAlarms, camera, photos }

class AppPermissionInfo {
  const AppPermissionInfo({
    required this.kind,
    required this.title,
    required this.reason,
    required this.status,
  });

  final AppPermissionKind kind;
  final String title;
  final String reason;
  final PermissionStatus status;

  bool get isGranted =>
      status == PermissionStatus.granted ||
      status == PermissionStatus.limited ||
      status == PermissionStatus.provisional;

  bool get isPermanentlyDenied =>
      status == PermissionStatus.permanentlyDenied ||
      status == PermissionStatus.restricted;
}

class DevicePermissionsService {
  const DevicePermissionsService();

  Permission? _permissionFor(AppPermissionKind kind) {
    switch (kind) {
      case AppPermissionKind.notifications:
        return Permission.notification;
      case AppPermissionKind.exactAlarms:
        return Platform.isAndroid ? Permission.scheduleExactAlarm : null;
      case AppPermissionKind.camera:
        return Permission.camera;
      case AppPermissionKind.photos:
        return Permission.photos;
    }
  }

  String _titleFor(AppPermissionKind kind) {
    switch (kind) {
      case AppPermissionKind.notifications:
        return 'Notifications';
      case AppPermissionKind.exactAlarms:
        return 'Alarms & reminders';
      case AppPermissionKind.camera:
        return 'Camera';
      case AppPermissionKind.photos:
        return 'Photos';
    }
  }

  String _reasonFor(AppPermissionKind kind) {
    switch (kind) {
      case AppPermissionKind.notifications:
        return 'Needed to show plan, bill, and medicine reminders on this device.';
      case AppPermissionKind.exactAlarms:
        return 'Lets reminders arrive at the exact time you set instead of being delayed.';
      case AppPermissionKind.camera:
        return 'Used to photograph warranty cards, receipts, and profile pictures.';
      case AppPermissionKind.photos:
        return 'Used to attach images from your gallery to assets and profiles.';
    }
  }

  List<AppPermissionKind> get _kinds {
    return [
      AppPermissionKind.notifications,
      if (Platform.isAndroid) AppPermissionKind.exactAlarms,
      AppPermissionKind.camera,
      // Android 13+ uses the system photo picker which needs no permission.
      if (Platform.isIOS) AppPermissionKind.photos,
    ];
  }

  Future<List<AppPermissionInfo>> load() async {
    final result = <AppPermissionInfo>[];
    for (final kind in _kinds) {
      final permission = _permissionFor(kind);
      if (permission == null) continue;
      final status = await permission.status;
      result.add(
        AppPermissionInfo(
          kind: kind,
          title: _titleFor(kind),
          reason: _reasonFor(kind),
          status: status,
        ),
      );
    }
    return result;
  }

  /// Requests the permission. Returns true if it ended up granted.
  Future<bool> request(AppPermissionKind kind) async {
    final permission = _permissionFor(kind);
    if (permission == null) return true;
    final status = await permission.request();
    return status.isGranted || status.isLimited || status.isProvisional;
  }

  Future<void> openSettings() => openAppSettings();
}

final devicePermissionsServiceProvider =
    Provider<DevicePermissionsService>((ref) => const DevicePermissionsService());

final devicePermissionsProvider =
    FutureProvider.autoDispose<List<AppPermissionInfo>>((ref) async {
  return ref.watch(devicePermissionsServiceProvider).load();
});

/// Permissions that block device reminders (notifications, exact alarms).
final deviceReminderBlockersProvider =
    FutureProvider.autoDispose<List<AppPermissionInfo>>((ref) async {
  final permissions = await ref.watch(devicePermissionsProvider.future);
  return permissions
      .where(
        (p) =>
            !p.isGranted &&
            (p.kind == AppPermissionKind.notifications ||
                p.kind == AppPermissionKind.exactAlarms),
      )
      .toList();
});
