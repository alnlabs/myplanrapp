import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../core/providers/theme_mode_provider.dart';
import '../../../core/strings/app_strings.dart';
import '../../../shared/providers/record_permissions.dart';
import '../../../shared/utils/legal_launcher.dart';
import '../../alerts/services/notification_service.dart';
import '../../app_updates/services/app_review_service.dart';
import '../../app_updates/services/app_update_service.dart';
import '../../auth/data/auth_repository.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../../shared/widgets/feature_screen_app_bar.dart';
import '../data/notification_settings.dart';
import '../data/device_permissions.dart';
import 'device_permissions_screen.dart';
import 'notification_sounds_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.signOutConfirmTitle),
        content: const Text(AppStrings.signOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.signOut),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(authRepositoryProvider).signOut();
    if (context.mounted) context.go('/login');
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteAccountTitle),
        content: const Text(AppStrings.deleteAccountBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text(AppStrings.deleteAccountConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(authRepositoryProvider).requestAccountDeletion();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.accountDeletionScheduled)),
        );
        context.go('/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text(AppStrings.updateChecking)),
    );
    final result = await AppUpdateService.instance.checkManually();
    final message = switch (result) {
      AppUpdateCheckResult.upToDate => AppStrings.updateUpToDate,
      AppUpdateCheckResult.updateStarted => AppStrings.updateStarted,
      AppUpdateCheckResult.notSupported => AppStrings.updateNotSupported,
      AppUpdateCheckResult.error => AppStrings.updateError,
    };
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickTheme(BuildContext context, WidgetRef ref) async {
    final current = ref.read(themeModeProvider);
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text(AppStrings.settingsTheme),
        children: ThemeMode.values
            .map(
              (mode) => RadioListTile<ThemeMode>(
                title: Text(_themeLabel(mode)),
                value: mode,
                groupValue: current,
                onChanged: (value) => Navigator.pop(context, value),
              ),
            )
            .toList(),
      ),
    );
    if (selected != null) {
      await ref.read(themeModeProvider.notifier).setMode(selected);
    }
  }

  String _themeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => AppStrings.settingsThemeSystem,
      ThemeMode.light => AppStrings.settingsThemeLight,
      ThemeMode.dark => AppStrings.settingsThemeDark,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final email = ref.watch(supabaseClientProvider).auth.currentUser?.email;
    final isOwner = ref.watch(isHouseholdOwnerProvider);

    return Scaffold(
      appBar: const FeatureScreenAppBar(
        title: AppStrings.settingsTitle,
        subtitle: AppStrings.settingsSubtitle,
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: AppStrings.settingsAccountSection),
          profileAsync.when(
            loading: () => const ListTile(
              leading: CircularProgressIndicator(),
              title: Text(AppStrings.profileTitle),
            ),
            error: (e, _) => ListTile(
              title: const Text(AppStrings.profileTitle),
              subtitle: Text(e.toString()),
            ),
            data: (profile) => ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(
                profile?.displayName ??
                    profile?.username ??
                    AppStrings.profileTitle,
              ),
              subtitle: email != null ? Text(email) : null,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
              ),
            ),
          ),
          const Divider(height: 1),
          const _SectionHeader(title: AppStrings.settingsAppearanceSection),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text(AppStrings.settingsTheme),
            subtitle: Text(_themeLabel(themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickTheme(context, ref),
          ),
          const Divider(height: 1),
          const _SectionHeader(title: AppStrings.settingsNotificationsSection),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text(AppStrings.settingsNotifications),
            subtitle: const Text(AppStrings.settingsNotificationsHint),
            value: notificationsEnabled,
            onChanged: (value) =>
                ref.read(notificationsEnabledProvider.notifier).setEnabled(value),
          ),
          ListTile(
            leading: const Icon(Icons.notification_add_outlined),
            title: const Text(AppStrings.settingsRequestNotificationPermission),
            subtitle: const Text(AppStrings.settingsExactAlarmHint),
            onTap: () async {
              final granted =
                  await NotificationService.instance.requestPermission();
              if (!context.mounted) return;
              final exactAllowed =
                  await NotificationService.instance.canScheduleExactReminders();
              if (!context.mounted) return;
              ref.invalidate(deviceReminderBlockersProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    granted && exactAllowed
                        ? AppStrings.settingsNotificationPermissionGranted
                        : granted
                            ? '${AppStrings.settingsNotificationPermissionDenied}. ${AppStrings.settingsExactAlarmHint}'
                            : AppStrings.settingsNotificationPermissionDenied,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.campaign_outlined),
            title: const Text(AppStrings.settingsTestNotification),
            subtitle: const Text(AppStrings.settingsTestNotificationHint),
            onTap: () async {
              final sent = await NotificationService.instance.showTestAlert();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    sent
                        ? AppStrings.settingsTestNotificationSent
                        : AppStrings.settingsNotificationPermissionDenied,
                  ),
                ),
              );
            },
          ),
          if (Platform.isAndroid)
            ListTile(
              leading: const Icon(Icons.music_note_outlined),
              title: const Text(AppStrings.notificationSoundsEntry),
              subtitle: const Text(AppStrings.notificationSoundsEntryHint),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationSoundsScreen(),
                ),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text(AppStrings.settingsPermissions),
            subtitle: const Text(AppStrings.settingsPermissionsHint),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DevicePermissionsScreen(),
              ),
            ),
          ),
          if (isOwner) ...[
            const Divider(height: 1),
            const _SectionHeader(title: AppStrings.settingsDataSection),
            ListTile(
              leading: Icon(
                Icons.restart_alt_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text(AppStrings.resetDataTitle),
              subtitle: const Text(AppStrings.moreResetHint),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/reset-data'),
            ),
          ],
          const Divider(height: 1),
          const _SectionHeader(title: AppStrings.settingsSupportSection),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text(AppStrings.rateApp),
            subtitle: const Text(AppStrings.rateAppHint),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => AppReviewService.instance.openStoreListing(),
          ),
          ListTile(
            leading: const Icon(Icons.system_update_outlined),
            title: const Text(AppStrings.checkForUpdates),
            subtitle: const Text(AppStrings.checkForUpdatesHint),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _checkForUpdates(context),
          ),
          const Divider(height: 1),
          const _SectionHeader(title: AppStrings.settingsLegalSection),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text(AppStrings.termsOfService),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => openTermsOfService(context),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text(AppStrings.privacyPolicy),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => openPrivacyPolicy(context),
          ),
          const Divider(height: 1),
          const _SectionHeader(title: AppStrings.settingsAboutSection),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text(AppStrings.appName),
            subtitle: Text(AppStrings.appVersion),
          ),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text(AppStrings.builtAndMaintainedBy),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => openCompanyWebsite(context),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: () => _signOut(context, ref),
              child: const Text(AppStrings.signOut),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              onPressed: () => _deleteAccount(context, ref),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text(AppStrings.deleteAccount),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
