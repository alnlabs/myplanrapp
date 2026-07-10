import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../alerts/data/notification_alert_type.dart';
import '../../alerts/data/notification_sound_settings.dart';
import '../../alerts/services/notification_service.dart';
import '../../alerts/services/notification_sound_picker.dart';

typedef NotificationSoundPickFn = Future<NotificationSoundPickResult> Function({
  String? currentUri,
});

typedef NotificationSoundPreviewFn = Future<bool> Function(
  NotificationAlertType type,
);

class NotificationSoundsScreen extends ConsumerWidget {
  const NotificationSoundsScreen({
    super.key,
    this.pickSound,
    this.previewSound,
  });

  final NotificationSoundPickFn? pickSound;
  final NotificationSoundPreviewFn? previewSound;

  static const _settingsChannel =
      MethodChannel('com.alnlabs.myplanr/notification_sounds');

  Future<void> _pickSound(
    BuildContext context,
    WidgetRef ref,
    NotificationAlertType type,
    NotificationSoundPreference current,
  ) async {
    final picked = await (pickSound ?? NotificationSoundPicker.pick)(
      currentUri: current.uri,
    );
    if (!context.mounted) return;

    if (picked.cancelled) return;

    await ref.read(notificationSoundPreferencesProvider.notifier).setPreference(
          type,
          uri: picked.uri,
          title: picked.title,
        );

    final previewed = await (previewSound ??
        NotificationService.instance.previewAlertSound)(type);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          previewed
              ? AppStrings.notificationSoundSaved
              : AppStrings.settingsNotificationPermissionDenied,
        ),
      ),
    );
  }

  Future<void> _resetSound(
    BuildContext context,
    WidgetRef ref,
    NotificationAlertType type,
  ) async {
    await ref
        .read(notificationSoundPreferencesProvider.notifier)
        .resetToDefault(type);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.notificationSoundReset)),
    );
  }

  Future<void> _openSystemNotificationSettings() async {
    if (!Platform.isAndroid) return;
    await _settingsChannel.invokeMethod<void>('openAppNotificationSettings');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesAsync = ref.watch(notificationSoundPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.notificationSoundsTitle)),
      body: preferencesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (preferences) {
          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(AppStrings.notificationSoundsHint),
              ),
              ...NotificationAlertType.settingsTypes.map((type) {
                final preference = preferences[type]!;
                final subtitle = preference.displayLabel(
                  AppStrings.notificationSoundDeviceDefault,
                );
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.music_note_outlined),
                      title: Text(type.settingsLabel),
                      subtitle: Text(subtitle),
                      trailing: preference.usesDeviceDefault
                          ? null
                          : IconButton(
                              tooltip: AppStrings.notificationSoundReset,
                              icon: const Icon(Icons.restart_alt),
                              onPressed: () => _resetSound(context, ref, type),
                            ),
                      onTap: () => _pickSound(context, ref, type, preference),
                    ),
                    const Divider(height: 1),
                  ],
                );
              }),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text(AppStrings.notificationSoundsSystemSettings),
                subtitle: const Text(AppStrings.notificationSoundsSystemSettingsHint),
                trailing: const Icon(Icons.open_in_new),
                onTap: _openSystemNotificationSettings,
              ),
            ],
          );
        },
      ),
    );
  }
}
