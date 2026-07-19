import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/models/medicine_schedule.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../reminders/data/reminder_repository.dart';
import '../../reminders/presentation/medicine_reminder_form_screen.dart';
import '../data/medicine_schedule_repository.dart';

/// Shows the medicines a family member takes (recurring reminders). Creating and
/// editing route through the shared medicine reminder form.
class FamilyMedicineSection extends ConsumerWidget {
  const FamilyMedicineSection({
    super.key,
    required this.familyMemberId,
    required this.canEdit,
  });

  final String familyMemberId;
  final bool canEdit;

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    MedicineSchedule? existing,
  }) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => MedicineReminderFormScreen(
          existing: existing,
          initialMemberId: familyMemberId,
        ),
      ),
    );
    if (saved == true) {
      ref.invalidate(medicineSchedulesProvider(familyMemberId));
      ref.invalidate(medicineRemindersTodayProvider);
      ref.invalidate(appRemindersProvider);
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
        content: Text('Remove ${schedule.displayTitle}?'),
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
      ref.invalidate(medicineRemindersTodayProvider);
      ref.invalidate(appRemindersProvider);
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
    final theme = Theme.of(context);
    final schedulesAsync = ref.watch(medicineSchedulesProvider(familyMemberId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.medicineSchedules,
                style: theme.textTheme.titleSmall,
              ),
            ),
            if (canEdit)
              TextButton.icon(
                onPressed: () => _openForm(context, ref),
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
                final subtitleParts = <String>[
                  if (schedule.medicineName != null &&
                      schedule.medicineName!.trim().isNotEmpty)
                    schedule.medicineName!.trim(),
                  if (schedule.dosage != null) schedule.dosage!,
                  if (schedule.timesLabel.isNotEmpty) schedule.timesLabel,
                  schedule.isActive ? AppStrings.active : AppStrings.inactive,
                ];

                return Card(
                  child: ListTile(
                    leading: Icon(
                      schedule.isActive
                          ? Icons.medication_outlined
                          : Icons.medication_liquid_outlined,
                      color: schedule.isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                    title: Text(schedule.medicineFor),
                    subtitle: Text(subtitleParts.join(' · ')),
                    onTap: canEdit
                        ? () => _openForm(context, ref, existing: schedule)
                        : null,
                    trailing: canEdit
                        ? PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _openForm(context, ref, existing: schedule);
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
