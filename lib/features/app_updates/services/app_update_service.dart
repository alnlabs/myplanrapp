import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

import '../../../core/strings/app_strings.dart';

/// Result of a manual "Check for updates" action, used to give UI feedback.
enum AppUpdateCheckResult {
  notSupported,
  upToDate,
  updateStarted,
  error,
}

/// Wraps Google Play in-app updates (Android only).
class AppUpdateService {
  AppUpdateService._();

  static final AppUpdateService instance = AppUpdateService._();

  /// Set as `MaterialApp.scaffoldMessengerKey` so we can surface the
  /// "update downloaded, restart" prompt from anywhere.
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  bool get _supported => Platform.isAndroid;

  /// Silent check on app start. Immediate (high-priority) updates are handled
  /// by Google's full-screen flow; optional updates download in the background
  /// and then prompt the user to restart.
  Future<void> checkOnStartup() async {
    if (!_supported) return;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) return;

      if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      } else if (info.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        _promptRestart();
      }
    } catch (_) {
      // Startup update checks are best-effort.
    }
  }

  /// Manual check triggered from Settings; returns a status for UI feedback.
  Future<AppUpdateCheckResult> checkManually() async {
    if (!_supported) return AppUpdateCheckResult.notSupported;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return AppUpdateCheckResult.upToDate;
      }

      if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return AppUpdateCheckResult.updateStarted;
      }
      if (info.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        _promptRestart();
        return AppUpdateCheckResult.updateStarted;
      }
      return AppUpdateCheckResult.upToDate;
    } catch (_) {
      return AppUpdateCheckResult.error;
    }
  }

  void _promptRestart() {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: const Text(AppStrings.updateDownloaded),
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: AppStrings.updateRestart,
          onPressed: () async {
            try {
              await InAppUpdate.completeFlexibleUpdate();
            } catch (_) {}
          },
        ),
      ),
    );
  }
}
