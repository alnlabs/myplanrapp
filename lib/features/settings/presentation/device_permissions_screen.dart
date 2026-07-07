import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../../alerts/services/notification_service.dart';
import '../data/device_permissions.dart';

class DevicePermissionsScreen extends ConsumerWidget {
  const DevicePermissionsScreen({super.key});

  Future<void> _handleTap(
    BuildContext context,
    WidgetRef ref,
    AppPermissionInfo info,
  ) async {
    final service = ref.read(devicePermissionsServiceProvider);

    if (info.isGranted) {
      await service.openSettings();
    } else if (info.isPermanentlyDenied) {
      await service.openSettings();
    } else {
      await service.request(info.kind);
      if (info.kind == AppPermissionKind.notifications) {
        await NotificationService.instance.requestPermission();
      }
    }

    ref.invalidate(devicePermissionsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsAsync = ref.watch(devicePermissionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsPermissions)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(devicePermissionsProvider),
        child: AsyncScreenBody(
          value: permissionsAsync,
          onRetry: () => ref.invalidate(devicePermissionsProvider),
          builder: (permissions) {
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: permissions.length + 1,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(AppStrings.settingsPermissionsHint),
                  );
                }
                final info = permissions[index - 1];
                return _PermissionTile(
                  info: info,
                  onTap: () => _handleTap(context, ref, info),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({required this.info, required this.onTap});

  final AppPermissionInfo info;
  final VoidCallback onTap;

  IconData get _icon {
    switch (info.kind) {
      case AppPermissionKind.notifications:
        return Icons.notifications_outlined;
      case AppPermissionKind.exactAlarms:
        return Icons.alarm_outlined;
      case AppPermissionKind.camera:
        return Icons.photo_camera_outlined;
      case AppPermissionKind.photos:
        return Icons.photo_library_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color statusColor;
    final String statusLabel;
    final String actionLabel;

    if (info.isGranted) {
      statusColor = Colors.green;
      statusLabel = AppStrings.permissionEnabled;
      actionLabel = AppStrings.permissionManage;
    } else if (info.isPermanentlyDenied) {
      statusColor = theme.colorScheme.error;
      statusLabel = AppStrings.permissionBlocked;
      actionLabel = AppStrings.permissionOpenSettings;
    } else {
      statusColor = theme.colorScheme.error;
      statusLabel = AppStrings.permissionDisabled;
      actionLabel = AppStrings.permissionEnable;
    }

    return ListTile(
      leading: Icon(_icon),
      title: Row(
        children: [
          Expanded(child: Text(info.title)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(info.reason),
            const SizedBox(height: 6),
            Text(
              actionLabel,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
          ],
        ),
      ),
      isThreeLine: true,
      onTap: onTap,
    );
  }
}
