import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/models/app_reminder_item.dart';
import '../../../shared/models/standalone_reminder.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/offline_guard.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_button.dart';
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
  }

  void _loadLinked(AppReminderItem item) {
    if (_loaded) return;
    _title.text = item.title;
    _reminderEnabled = true;
    _reminderAt = item.reminderAt ?? DateTime.now().add(const Duration(hours: 1));
    _loaded = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_reminderEnabled && _reminderAt == null) {
      setState(() => _error = AppStrings.reminderAt);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      ref.ensureOnline();
      final repo = ref.read(reminderRepositoryProvider);

      if (_isLinked) {
        final item = widget.linkedItem!;
        switch (item.sourceType) {
          case ReminderSourceType.plan:
            await repo.updatePlanReminder(
              planId: item.sourceId,
              reminderAt: _reminderAt!,
              enabled: _reminderEnabled,
            );
          case ReminderSourceType.subscription:
            await repo.updateSubscriptionReminder(
              subscriptionId: item.sourceId,
              reminderAt: _reminderAt!,
              enabled: _reminderEnabled,
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
              notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
              reminderAt: _reminderAt!,
              isActive: _reminderEnabled,
            ),
          );
        } else {
          await repo.createStandalone(
            householdId: householdId,
            title: _title.text.trim(),
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
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
      final reminderAsync = ref.watch(standaloneReminderProvider(widget.standaloneId!));
      reminderAsync.whenData((data) {
        if (data != null) _loadStandalone(data);
      });
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (linked != null) ...[
              _SourceChip(item: linked),
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              const Text(AppStrings.reminderMedicineEditHint),
              const SizedBox(height: 16),
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
              ),
              if (!_isLinked) ...[
                const SizedBox(height: 12),
                AppTextField(
                  controller: _notes,
                  label: AppStrings.reminderNotes,
                  maxLines: 3,
                ),
              ],
              const SizedBox(height: 8),
              ReminderField(
                enabled: _reminderEnabled,
                reminderAt: _reminderAt,
                onEnabledChanged: (value) => setState(() => _reminderEnabled = value),
                onReminderAtChanged: (value) => setState(() => _reminderAt = value),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              LoadingButton(
                onPressed: _loading ? null : _submit,
                isLoading: _loading,
                label: AppStrings.save,
              ),
            ],
          ],
        ),
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
