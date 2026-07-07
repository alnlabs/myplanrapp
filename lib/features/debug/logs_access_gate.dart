import 'package:flutter/material.dart';

import '../../core/config/env.dart';
import '../../core/strings/app_strings.dart';
import '../../shared/widgets/app_text_field.dart';
import 'presentation/logs_screen.dart';

/// Opens diagnostic logs only after the correct PIN is entered.
class LogsAccessGate {
  LogsAccessGate._();

  static int _failedAttempts = 0;
  static DateTime? _lockedUntil;

  static bool get _isLocked {
    final until = _lockedUntil;
    if (until == null) return false;
    if (DateTime.now().isAfter(until)) {
      _lockedUntil = null;
      _failedAttempts = 0;
      return false;
    }
    return true;
  }

  /// After [SecretTap] reaches 7 taps, call this to prompt for the PIN.
  static Future<void> openIfAuthorized(BuildContext context) async {
    if (_isLocked) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.logsAccessLocked)),
        );
      }
      return;
    }

    if (!Env.isLogsPinConfigured) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.logsPinNotConfigured)),
        );
      }
      return;
    }

    final authorized = await _promptForPin(context);
    if (authorized && context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const LogsScreen()),
      );
    }
  }

  static Future<bool> _promptForPin(BuildContext context) async {
    final controller = TextEditingController();
    var errorText = '';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(AppStrings.logsPinTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(AppStrings.logsPinBody),
                  const SizedBox(height: 16),
                  AppPasswordField(
                    controller: controller,
                    label: AppStrings.logsPinLabel,
                    textInputAction: TextInputAction.done,
                  ),
                  if (errorText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorText,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text(AppStrings.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    if (Env.matchesLogsPin(controller.text)) {
                      _failedAttempts = 0;
                      _lockedUntil = null;
                      Navigator.pop(dialogContext, true);
                    } else {
                      setDialogState(() => errorText = _registerFailure());
                    }
                  },
                  child: const Text(AppStrings.logsPinUnlock),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    return result ?? false;
  }

  static String _registerFailure() {
    _failedAttempts++;
    if (_failedAttempts >= 7) {
      _lockedUntil = DateTime.now().add(const Duration(minutes: 5));
      _failedAttempts = 0;
      return AppStrings.logsAccessLocked;
    }
    return AppStrings.logsPinWrong;
  }
}
