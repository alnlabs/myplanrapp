import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/models/medicine_schedule.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/date_time_picker.dart';
import '../../../shared/utils/schedule_time_parser.dart';
import '../data/medicine_schedule_repository.dart';

class MedicineSchedulesSection extends ConsumerWidget {
  const MedicineSchedulesSection({
    super.key,
    required this.familyMemberId,
    required this.householdId,
    required this.canEdit,
  });

  final String familyMemberId;
  final String householdId;
  final bool canEdit;

  Future<void> _showForm(
    BuildContext context,
    WidgetRef ref, {
    MedicineSchedule? existing,
  }) async {
    final nameController = TextEditingController(text: existing?.medicineName);
    final dosageController = TextEditingController(text: existing?.dosage);
    var times = existing?.timesPerDay
            .map(parseScheduleTime)
            .whereType<TimeOfDay>()
            .toList() ??
        <TimeOfDay>[];
    var isActive = existing?.isActive ?? true;

    Future<void> addTime(StateSetter setDialogState) async {
      final picked = await pickTime(
        context,
        initial: times.isEmpty ? const TimeOfDay(hour: 8, minute: 0) : times.last,
      );
      if (picked == null) return;
      setDialogState(() {
        final duplicate = times.any(
          (t) => t.hour == picked.hour && t.minute == picked.minute,
        );
        if (!duplicate) times.add(picked);
      });
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            existing == null
                ? AppStrings.addMedicineSchedule
                : AppStrings.editMedicineSchedule,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.medicineName,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dosageController,
                  decoration: const InputDecoration(labelText: AppStrings.dosage),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppStrings.timesPerDay,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 8),
                if (times.isEmpty)
                  Text(
                    AppStrings.timesPerDayHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (times.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < times.length; i++)
                        InputChip(
                          label: Text(formatScheduleTime(times[i])),
                          onDeleted: () =>
                              setDialogState(() => times.removeAt(i)),
                        ),
                    ],
                  ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => addTime(setDialogState),
                    icon: const Icon(Icons.access_time),
                    label: const Text(AppStrings.addReminderTime),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(isActive ? AppStrings.active : AppStrings.inactive),
                  value: isActive,
                  onChanged: (v) => setDialogState(() => isActive = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !context.mounted) return;

    if (times.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.timesPerDayHint)),
        );
      }
      return;
    }

    final timeStrings = times.map(formatScheduleTime).toList()..sort();

    try {
      final repo = ref.read(medicineScheduleRepositoryProvider);
      if (existing == null) {
        await repo.createSchedule(
          MedicineSchedule(
            id: '',
            familyMemberId: familyMemberId,
            householdId: householdId,
            medicineName: nameController.text.trim(),
            dosage: dosageController.text.trim().isEmpty
                ? null
                : dosageController.text.trim(),
            timesPerDay: timeStrings,
            isActive: isActive,
          ),
        );
      } else {
        await repo.updateSchedule(
          MedicineSchedule(
            id: existing.id,
            familyMemberId: familyMemberId,
            householdId: householdId,
            medicineName: nameController.text.trim(),
            dosage: dosageController.text.trim().isEmpty
                ? null
                : dosageController.text.trim(),
            timesPerDay: timeStrings,
            isActive: isActive,
          ),
        );
      }
      ref.invalidate(medicineSchedulesProvider(familyMemberId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorFormatter.format(e))),
        );
      }
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    MedicineSchedule schedule,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.delete),
        content: Text('Remove ${schedule.medicineName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(medicineScheduleRepositoryProvider)
          .deleteSchedule(schedule.id);
      ref.invalidate(medicineSchedulesProvider(familyMemberId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorFormatter.format(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(medicineSchedulesProvider(familyMemberId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.medicineSchedules,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            if (canEdit)
              TextButton.icon(
                onPressed: () => _showForm(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: const Text(AppStrings.add),
              ),
          ],
        ),
        const SizedBox(height: 8),
        schedulesAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(ApiErrorFormatter.format(e)),
          data: (schedules) {
            if (schedules.isEmpty) {
              return const Text(AppStrings.noMedicineSchedules);
            }
            return Column(
              children: schedules.map((schedule) {
                return Card(
                  child: ListTile(
                    leading: Icon(
                      schedule.isActive
                          ? Icons.medication_outlined
                          : Icons.medication_liquid_outlined,
                      color: schedule.isActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                    title: Text(schedule.medicineName),
                    subtitle: Text(
                      [
                        if (schedule.dosage != null) schedule.dosage!,
                        if (schedule.timesLabel.isNotEmpty)
                          schedule.timesLabel,
                        schedule.isActive
                            ? AppStrings.active
                            : AppStrings.inactive,
                      ].join(' · '),
                    ),
                    trailing: canEdit
                        ? PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showForm(context, ref, existing: schedule);
                              } else if (value == 'delete') {
                                _delete(context, ref, schedule);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text(AppStrings.edit),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(AppStrings.delete),
                              ),
                            ],
                          )
                        : null,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
