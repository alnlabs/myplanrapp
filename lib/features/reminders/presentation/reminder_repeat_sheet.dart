import 'package:flutter/material.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/reminder_repeat.dart';
import '../../../shared/models/reminder_repeat_spec.dart';
import '../../../shared/utils/reminder_recurrence.dart';

/// Opens the repeat-pattern editor and returns the chosen spec, or null if the
/// user cancelled.
Future<ReminderRepeatSpec?> showReminderRepeatSheet(
  BuildContext context, {
  required ReminderRepeatSpec initial,
  required DateTime anchor,
}) {
  return showModalBottomSheet<ReminderRepeatSpec>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _RepeatSheet(initial: initial, anchor: anchor),
  );
}

class _RepeatSheet extends StatefulWidget {
  const _RepeatSheet({required this.initial, required this.anchor});

  final ReminderRepeatSpec initial;
  final DateTime anchor;

  @override
  State<_RepeatSheet> createState() => _RepeatSheetState();
}

class _RepeatSheetState extends State<_RepeatSheet> {
  late String _frequency;
  late int _interval;
  late Set<int> _days;
  late MonthlyMode _monthlyMode;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _frequency = s.frequency;
    _interval = s.interval < 1 ? 1 : s.interval;
    _days = s.sortedDays.toSet();
    _monthlyMode = s.monthlyMode;
  }

  ReminderRepeatSpec get _spec => ReminderRepeatSpec(
        frequency: _frequency,
        interval: _interval,
        daysOfWeek: _days.toList()..sort(),
        monthlyMode: _monthlyMode,
      );

  bool get _isRecurring => ReminderRepeat.isRecurring(_frequency);

  String get _unitLabel {
    final plural = _interval != 1;
    return switch (_frequency) {
      ReminderRepeat.daily => plural ? 'days' : 'day',
      ReminderRepeat.weekly => plural ? 'weeks' : 'week',
      ReminderRepeat.monthly => plural ? 'months' : 'month',
      ReminderRepeat.yearly => plural ? 'years' : 'year',
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.reminderRepeatLabel,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _FrequencyChips(
              value: _frequency,
              onChanged: (value) => setState(() {
                _frequency = value;
                if (value == ReminderRepeat.weekly && _days.isEmpty) {
                  _days = {widget.anchor.weekday};
                }
              }),
            ),
            if (_isRecurring) ...[
              const SizedBox(height: 20),
              _IntervalStepper(
                interval: _interval,
                unitLabel: _unitLabel,
                onChanged: (value) => setState(() => _interval = value),
              ),
            ],
            if (_frequency == ReminderRepeat.weekly) ...[
              const SizedBox(height: 20),
              _WeekdayPicker(
                selected: _days,
                onPresetWeekdays: () =>
                    setState(() => _days = ReminderWeekdays.weekdays.toSet()),
                onPresetWeekend: () =>
                    setState(() => _days = ReminderWeekdays.weekend.toSet()),
                onToggle: (day) => setState(() {
                  if (_days.contains(day)) {
                    if (_days.length > 1) _days.remove(day);
                  } else {
                    _days.add(day);
                  }
                }),
              ),
            ],
            if (_frequency == ReminderRepeat.monthly) ...[
              const SizedBox(height: 12),
              _MonthlyModePicker(
                mode: _monthlyMode,
                anchor: widget.anchor,
                onChanged: (mode) => setState(() => _monthlyMode = mode),
              ),
            ],
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_repeat_outlined,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ReminderRecurrence.describe(_spec, widget.anchor),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(AppStrings.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, _spec),
                    child: const Text(AppStrings.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FrequencyChips extends StatelessWidget {
  const _FrequencyChips({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  static const _options = [
    (value: ReminderRepeat.none, label: 'Does not repeat'),
    (value: ReminderRepeat.daily, label: 'Daily'),
    (value: ReminderRepeat.weekly, label: 'Weekly'),
    (value: ReminderRepeat.monthly, label: 'Monthly'),
    (value: ReminderRepeat.yearly, label: 'Yearly'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in _options)
          ChoiceChip(
            label: Text(option.label),
            selected: value == option.value,
            onSelected: (_) => onChanged(option.value),
          ),
      ],
    );
  }
}

class _IntervalStepper extends StatelessWidget {
  const _IntervalStepper({
    required this.interval,
    required this.unitLabel,
    required this.onChanged,
  });

  final int interval;
  final String unitLabel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text('Every', style: theme.textTheme.bodyLarge),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          onPressed: interval > 1 ? () => onChanged(interval - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 44,
          child: Text(
            '$interval',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton.filledTonal(
          onPressed: interval < 99 ? () => onChanged(interval + 1) : null,
          icon: const Icon(Icons.add),
        ),
        const SizedBox(width: 12),
        Text(unitLabel, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}

class _WeekdayPicker extends StatelessWidget {
  const _WeekdayPicker({
    required this.selected,
    required this.onToggle,
    required this.onPresetWeekdays,
    required this.onPresetWeekend,
  });

  final Set<int> selected;
  final ValueChanged<int> onToggle;
  final VoidCallback onPresetWeekdays;
  final VoidCallback onPresetWeekend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Repeat on',
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (var day = 1; day <= 7; day++)
              FilterChip(
                label: Text(ReminderWeekdays.shortLabel(day)),
                selected: selected.contains(day),
                onSelected: (_) => onToggle(day),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(Icons.work_outline, size: 16),
              label: const Text('Weekdays'),
              onPressed: onPresetWeekdays,
            ),
            ActionChip(
              avatar: const Icon(Icons.weekend_outlined, size: 16),
              label: const Text('Weekend'),
              onPressed: onPresetWeekend,
            ),
          ],
        ),
      ],
    );
  }
}

class _MonthlyModePicker extends StatelessWidget {
  const _MonthlyModePicker({
    required this.mode,
    required this.anchor,
    required this.onChanged,
  });

  final MonthlyMode mode;
  final DateTime anchor;
  final ValueChanged<MonthlyMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final nth = ((anchor.day - 1) ~/ 7) + 1;
    final nthLabel = switch (nth) {
      1 => '1st',
      2 => '2nd',
      3 => '3rd',
      4 => '4th',
      _ => 'last',
    };
    final weekday = ReminderWeekdays.longLabel(anchor.weekday);

    return Column(
      children: [
        RadioListTile<MonthlyMode>(
          contentPadding: EdgeInsets.zero,
          value: MonthlyMode.dayOfMonth,
          groupValue: mode,
          onChanged: (v) => onChanged(v!),
          title: Text('On day ${anchor.day}'),
        ),
        RadioListTile<MonthlyMode>(
          contentPadding: EdgeInsets.zero,
          value: MonthlyMode.nthWeekday,
          groupValue: mode,
          onChanged: (v) => onChanged(v!),
          title: Text('On the $nthLabel $weekday'),
        ),
      ],
    );
  }
}
