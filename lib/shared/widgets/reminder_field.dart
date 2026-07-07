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
  });

  final bool enabled;
  final DateTime? reminderAt;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<DateTime?> onReminderAtChanged;
  final String? subtitle;
  final DateTime? firstDate;

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
                  : 'Tap to set date & time',
            ),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: () => _pick(context),
          ),
      ],
    );
  }
}
