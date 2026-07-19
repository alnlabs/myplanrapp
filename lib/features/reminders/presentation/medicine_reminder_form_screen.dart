import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/medicine_constants.dart';
import '../../../shared/models/family_member.dart';
import '../../../shared/models/medicine_schedule.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/date_time_picker.dart';
import '../../../shared/utils/schedule_time_parser.dart';
import '../../auth/data/auth_repository.dart';
import '../../household/data/family_repository.dart';
import '../../household/data/medicine_schedule_repository.dart';
import '../../household/utils/medicine_form_validators.dart';
import '../data/reminder_repository.dart';

/// Create/edit a recurring "take medicine" reminder (a member medicine
/// schedule) from the Plans & Reminders flow.
class MedicineReminderFormScreen extends ConsumerStatefulWidget {
  const MedicineReminderFormScreen({
    super.key,
    this.existing,
    this.initialMemberId,
  });

  final MedicineSchedule? existing;

  /// Preselects "For member" when creating from a family member's screen.
  final String? initialMemberId;

  @override
  ConsumerState<MedicineReminderFormScreen> createState() =>
      _MedicineReminderFormScreenState();
}

class _MedicineReminderFormScreenState
    extends ConsumerState<MedicineReminderFormScreen> {
  late final TextEditingController _customPurpose;
  late final TextEditingController _brand;
  late final TextEditingController _dosage;

  String? _memberId;
  String? _selectedPurpose;
  late List<TimeOfDay> _times;
  bool _active = true;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _memberId = e?.familyMemberId ?? widget.initialMemberId;
    _selectedPurpose = initialMedicinePurposeSelection(e);
    _customPurpose =
        TextEditingController(text: initialMedicineCustomPurpose(e));
    _brand = TextEditingController(text: e?.medicineName ?? '');
    _dosage = TextEditingController(text: e?.dosage ?? '');
    _times = e?.timesPerDay
            .map(parseScheduleTime)
            .whereType<TimeOfDay>()
            .toList() ??
        <TimeOfDay>[];
    _active = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _customPurpose.dispose();
    _brand.dispose();
    _dosage.dispose();
    super.dispose();
  }

  Future<void> _addTime() async {
    final picked = await pickTime(
      context,
      initial: _times.isEmpty ? const TimeOfDay(hour: 8, minute: 0) : _times.last,
    );
    if (picked == null) return;
    setState(() {
      final dup =
          _times.any((t) => t.hour == picked.hour && t.minute == picked.minute);
      if (!dup) _times.add(picked);
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (_memberId == null) {
      _snack(AppStrings.medicineMemberRequired);
      return;
    }
    final purposeError = validateMedicinePurpose(
      selectedPurpose: _selectedPurpose,
      customPurposeText: _customPurpose.text,
    );
    if (purposeError != null) {
      _snack(purposeError);
      return;
    }
    final timesError = validateMedicineTimes(_times.length);
    if (timesError != null) {
      _snack(timesError);
      return;
    }

    final medicineFor = resolveMedicinePurpose(
      selectedPurpose: _selectedPurpose,
      customPurposeText: _customPurpose.text,
    );
    final timeStrings = _times.map(formatScheduleTime).toList()..sort();
    final brand = _brand.text.trim();
    final dosage = _dosage.text.trim();

    setState(() => _saving = true);
    try {
      final profile = await ref.read(userProfileProvider.future);
      final householdId = profile?.activeHouseholdId;
      if (householdId == null) throw StateError('No active household');

      final repo = ref.read(medicineScheduleRepositoryProvider);
      final schedule = MedicineSchedule(
        id: widget.existing?.id ?? '',
        familyMemberId: _memberId!,
        householdId: householdId,
        medicineFor: medicineFor,
        medicineName: brand.isEmpty ? null : brand,
        dosage: dosage.isEmpty ? null : dosage,
        timesPerDay: timeStrings,
        isActive: _active,
      );
      if (_isEdit) {
        await repo.updateSchedule(schedule);
      } else {
        await repo.createSchedule(schedule);
      }
      ref.invalidate(medicineSchedulesProvider(_memberId!));
      ref.invalidate(medicineRemindersTodayProvider);
      ref.invalidate(appRemindersProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _snack(ApiErrorFormatter.format(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rosterAsync = ref.watch(familyRosterProvider);
    final showCustom = _selectedPurpose == MedicinePurposes.other;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit
            ? AppStrings.editMedicineSchedule
            : AppStrings.addMedicineSchedule),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          rosterAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(ApiErrorFormatter.format(e)),
            data: (roster) {
              final members =
                  roster.where((m) => !m.isPendingInvite).toList();
              return DropdownButtonFormField<String>(
                value: _memberId,
                decoration:
                    const InputDecoration(labelText: AppStrings.forMember),
                items: members
                    .map((FamilyMember m) => DropdownMenuItem(
                          value: m.id,
                          child: Text(m.listLabel),
                        ))
                    .toList(),
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _memberId = v),
              );
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedPurpose,
            decoration: const InputDecoration(labelText: AppStrings.medicineFor),
            items: MedicinePurposes.all
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: _saving
                ? null
                : (v) => setState(() => _selectedPurpose = v),
          ),
          if (showCustom) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customPurpose,
              decoration: const InputDecoration(
                labelText: AppStrings.medicineForOther,
                hintText: AppStrings.medicineForHint,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _brand,
            decoration: const InputDecoration(
              labelText: AppStrings.medicineBrandOptional,
              hintText: AppStrings.medicineBrandHint,
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dosage,
            decoration: const InputDecoration(labelText: AppStrings.dosage),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppStrings.timesPerDay,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(height: 8),
          if (_times.isEmpty)
            Text(
              AppStrings.timesPerDayHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (_times.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _times.length; i++)
                  InputChip(
                    label: Text(formatScheduleTime(_times[i])),
                    onDeleted:
                        _saving ? null : () => setState(() => _times.removeAt(i)),
                  ),
              ],
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _saving ? null : _addTime,
              icon: const Icon(Icons.access_time),
              label: const Text(AppStrings.addReminderTime),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_active ? AppStrings.active : AppStrings.inactive),
            value: _active,
            onChanged: _saving ? null : (v) => setState(() => _active = v),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_saving ? AppStrings.loading : AppStrings.save),
            ),
          ),
        ],
      ),
    );
  }
}
