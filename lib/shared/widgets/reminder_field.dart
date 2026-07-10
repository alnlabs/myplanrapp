import 'package:flutter/material.dart';

import '../../core/strings/app_strings.dart';
import '../utils/date_time_picker.dart';
import '../utils/formatters.dart';

class ReminderField extends StatelessWidget {
  const ReminderField({
    super.key,
    required this.enabled,
    required this.reminderAt,
    required this.onEnabledChanged,
    required this.onReminderAtChanged,
    this.subtitle,
    this.firstDate,
    this.errorText,
  });

  final bool enabled;
  final DateTime? reminderAt;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<DateTime?> onReminderAtChanged;
  final String? subtitle;
  final DateTime? firstDate;
  final String? errorText;

  Future<void> _pick(BuildContext context) async {
    final picked = await pickDateTime(
      context,
      initial: reminderAt ?? DateTime.now(),
      firstDate: firstDate ?? DateTime.now(),
    );
    if (picked != null) onReminderAtChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(AppStrings.reminder),
          subtitle: subtitle != null ? Text(subtitle!) : null,
          value: enabled,
          onChanged: (value) async {
            if (!value) {
              onEnabledChanged(false);
              onReminderAtChanged(null);
              return;
            }
            onEnabledChanged(true);
            if (reminderAt == null) await _pick(context);
          },
        ),
        if (enabled)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.reminderAt),
            subtitle: Text(
              reminderAt != null
                  ? Formatters.dateTime(reminderAt!.toLocal())
                  : AppStrings.tapToSetDateTime,
            ),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: () => _pick(context),
          ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}
