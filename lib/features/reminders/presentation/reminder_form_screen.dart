import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/models/app_reminder_item.dart';
import '../../../shared/models/standalone_reminder.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/offline_guard.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/form_screen_body.dart';
import '../../../shared/widgets/reminder_field.dart';
import '../../auth/data/auth_repository.dart';
import '../../household/presentation/household_screen.dart';
import '../data/reminder_repository.dart';

class ReminderFormScreen extends ConsumerStatefulWidget {
  const ReminderFormScreen({
    super.key,
    this.standaloneId,
    this.linkedItem,
  });

  final String? standaloneId;
  final AppReminderItem? linkedItem;

  @override
  ConsumerState<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends ConsumerState<ReminderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _notes = TextEditingController();

  bool _reminderEnabled = true;
  DateTime? _reminderAt;
  bool _loading = false;
  bool _loaded = false;
  String? _error;
  String? _reminderError;

  bool get _isLinked => widget.linkedItem != null;
  bool get _isEdit => widget.standaloneId != null || _isLinked;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _loadStandalone(StandaloneReminder reminder) {
    if (_loaded) return;
    _title.text = reminder.title;
    _notes.text = reminder.notes ?? '';
    _reminderEnabled = reminder.isActive;
    _reminderAt = reminder.reminderAt;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _loadLinked(AppReminderItem item) {
    if (_loaded) return;
    _title.text = item.title;
    _notes.text = item.notes ?? '';
    _reminderEnabled = true;
    _reminderAt = item.reminderAt ?? DateTime.now().add(const Duration(hours: 1));
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final reminderError = Validators.reminderDateTime(
      enabled: _reminderEnabled,
      reminderAt: _reminderAt,
    );
    if (reminderError != null) {
      setState(() => _reminderError = reminderError);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _reminderError = null;
    });

    try {
      ref.ensureOnline();
      final repo = ref.read(reminderRepositoryProvider);
      final notesText =
          _notes.text.trim().isEmpty ? null : _notes.text.trim();

      if (_isLinked) {
        final item = widget.linkedItem!;
        switch (item.sourceType) {
          case ReminderSourceType.plan:
            await repo.updatePlanReminder(
              planId: item.sourceId,
              reminderAt: _reminderAt!,
              enabled: _reminderEnabled,
              description: notesText,
            );
          case ReminderSourceType.subscription:
            await repo.updateSubscriptionReminder(
              subscriptionId: item.sourceId,
              reminderAt: _reminderAt!,
              enabled: _reminderEnabled,
              notes: notesText,
            );
          case ReminderSourceType.medicine:
          case ReminderSourceType.standalone:
            break;
        }
      } else {
        final profile = await ref.read(userProfileProvider.future);
        final householdId = profile?.activeHouseholdId;
        if (householdId == null) throw Exception('No household');

        if (widget.standaloneId != null) {
          final existing =
              await repo.fetchStandaloneById(widget.standaloneId!);
          if (existing == null) throw Exception('Reminder not found');
          await repo.updateStandalone(
            existing.copyWith(
              title: _title.text.trim(),
              notes: notesText,
              reminderAt: _reminderAt!,
              isActive: _reminderEnabled,
            ),
          );
        } else {
          await repo.createStandalone(
            householdId: householdId,
            title: _title.text.trim(),
            notes: notesText,
            reminderAt: _reminderAt!,
          );
        }
      }

      ref.invalidate(appRemindersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.reminderSaved)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _error = ApiErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.standaloneId != null) {
      final reminderAsync =
          ref.watch(standaloneReminderProvider(widget.standaloneId!));
      reminderAsync.whenData((data) {
        if (data != null) _loadStandalone(data);
      });
      if (!_loaded) {
        return Scaffold(
          appBar: AppBar(
            title:
                Text(_isEdit ? AppStrings.editReminder : AppStrings.addReminder),
          ),
          body: reminderAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppStrings.errorGeneric),
                  TextButton(
                    onPressed: () => ref.invalidate(
                      standaloneReminderProvider(widget.standaloneId!),
                    ),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            ),
            data: (data) {
              if (data == null) {
                return Center(child: Text(AppStrings.errorGeneric));
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        );
      }
    } else if (widget.linkedItem != null) {
      _loadLinked(widget.linkedItem!);
    }

    final linked = widget.linkedItem;
    final isMedicine = linked?.sourceType == ReminderSourceType.medicine;
    final medicineItem = isMedicine ? linked! : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? AppStrings.editReminder : AppStrings.addReminder),
      ),
      body: FormScreenBody(
        formKey: _formKey,
        padding: const EdgeInsets.all(24),
        children: [
          if (linked != null) ...[
            _SourceChip(item: linked),
            const SizedBox(height: kFormFieldSpacing),
          ],
          if (medicineItem != null) ...[
            Text(
              medicineItem.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (medicineItem.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                medicineItem.subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: kFormFieldSpacing),
            const Text(AppStrings.reminderMedicineEditHint),
            const SizedBox(height: kFormFieldSpacing),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const HouseholdScreen(),
                ),
              ),
              icon: const Icon(Icons.family_restroom_outlined),
              label: const Text(AppStrings.householdTitle),
            ),
          ] else ...[
            AppTextField(
              controller: _title,
              label: AppStrings.reminderTitle,
              validator: Validators.required,
              readOnly: _isLinked,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: kFormFieldSpacing),
            AppTextField(
              controller: _notes,
              label: AppStrings.reminderNotes,
              helperText: AppStrings.reminderNotesHint,
              maxLines: 3,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: kFormFieldSpacing),
            ReminderField(
              enabled: _reminderEnabled,
              reminderAt: _reminderAt,
              errorText: _reminderError,
              onEnabledChanged: (value) => setState(() {
                _reminderEnabled = value;
                _reminderError = null;
              }),
              onReminderAtChanged: (value) => setState(() {
                _reminderAt = value;
                _reminderError = null;
              }),
            ),
            const SizedBox(height: 24),
            FormSaveSection(
              error: _error,
              saveLabel: AppStrings.save,
              isLoading: _loading,
              onSave: _submit,
            ),
          ],
        ],
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.item});

  final AppReminderItem item;

  @override
  Widget build(BuildContext context) {
    final label = switch (item.sourceType) {
      ReminderSourceType.plan => AppStrings.reminderSourcePlan,
      ReminderSourceType.subscription => AppStrings.reminderSourceSubscription,
      ReminderSourceType.medicine => AppStrings.reminderSourceMedicine,
      ReminderSourceType.standalone => AppStrings.reminderSourceStandalone,
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        avatar: Icon(_iconFor(item.sourceType), size: 18),
        label: Text(label),
      ),
    );
  }

  IconData _iconFor(ReminderSourceType type) {
    return switch (type) {
      ReminderSourceType.plan => Icons.event_note_outlined,
      ReminderSourceType.subscription => Icons.subscriptions_outlined,
      ReminderSourceType.medicine => Icons.medication_outlined,
      ReminderSourceType.standalone => Icons.notifications_outlined,
    };
  }
}
