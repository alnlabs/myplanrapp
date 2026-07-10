import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/meal_slots.dart';
import '../../../shared/constants/plan_constants.dart';
import '../../../shared/models/plan.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/date_time_picker.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/reminder_field.dart';
import '../../../shared/utils/offline_guard.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/form_error_banner.dart';
import '../../../shared/widgets/form_screen_body.dart';
import '../../auth/data/auth_repository.dart';
import '../../household/data/family_repository.dart';
import '../data/plan_repository.dart';
import '../data/plans_list_provider.dart';

class PlanFormScreen extends ConsumerStatefulWidget {
  const PlanFormScreen({
    super.key,
    this.planId,
    this.initialPlanType,
    this.initialMealSlot,
  });

  final String? planId;
  final String? initialPlanType;
  final String? initialMealSlot;

  @override
  ConsumerState<PlanFormScreen> createState() => _PlanFormScreenState();
}

class _PlanFormScreenState extends ConsumerState<PlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();

  String _planType = PlanTypes.task;
  String _scope = PlanScopes.household;
  DateTime? _dueAt;
  bool _reminderEnabled = false;
  DateTime? _reminderAt;
  String? _aboutMemberId;
  String? _assignedToId;
  String? _mealSlot;
  bool _loading = false;
  bool _loaded = false;
  String? _error;
  String? _reminderError;

  bool get _isEdit => widget.planId != null;

  @override
  void initState() {
    super.initState();
    final initialType = widget.initialPlanType;
    if (initialType != null &&
        PlanTypes.all.any((type) => type.value == initialType)) {
      _planType = initialType;
    }
    final initialSlot = widget.initialMealSlot;
    if (initialSlot != null && MealSlots.isValid(initialSlot)) {
      _mealSlot = initialSlot;
    } else if (_planType == PlanTypes.meal) {
      _mealSlot = MealSlots.lunch;
    }
    if (_planType == PlanTypes.meal && _mealSlot != null && _dueAt == null) {
      _dueAt = MealSlots.defaultDueAtForSlot(_mealSlot!);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _loadPlan(Plan plan) {
    if (_loaded) return;
    _title.text = plan.title;
    _description.text = plan.description ?? '';
    _planType = plan.planType;
    _scope = plan.scope;
    _dueAt = plan.dueAt;
    _reminderEnabled = plan.reminderEnabled;
    _reminderAt = plan.reminderAt;
    _aboutMemberId = plan.aboutMemberId;
    _assignedToId = plan.assignedTo;
    _mealSlot = plan.mealSlot;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _pickDueDate() async {
    final picked = await pickDateTime(
      context,
      initial: _dueAt ?? DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() => _dueAt = picked);
  }

  Plan _buildPlan({Plan? existing}) {
    return Plan(
      id: existing?.id ?? '',
      householdId: existing?.householdId ?? '',
      createdBy: existing?.createdBy ?? '',
      scope: _scope,
      planType: _planType,
      title: _title.text.trim(),
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      status: existing?.status ?? 'open',
      dueAt: _dueAt,
      reminderEnabled: _reminderEnabled,
      reminderAt: _reminderEnabled ? _reminderAt : null,
      aboutMemberId: _aboutMemberId,
      assignedTo: _assignedToId,
      reminderNotifyUserId: existing?.reminderNotifyUserId,
      recipeId: existing?.recipeId,
      mealSlot: _planType == PlanTypes.meal ? _mealSlot : null,
      completedAt: existing?.completedAt,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_planType == PlanTypes.meal && !MealSlots.isValid(_mealSlot)) {
      setState(() => _error = AppStrings.mealSlotRequired);
      return;
    }
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
      final profile = await ref.read(userProfileProvider.future);
      final householdId = profile?.activeHouseholdId;
      if (householdId == null) throw Exception(AppStrings.noHousehold);

      final repo = ref.read(planRepositoryProvider);

      if (_isEdit) {
        final existing = await repo.fetchPlan(widget.planId!);
        if (existing == null) throw Exception(AppStrings.errorGeneric);
        await repo.updatePlan(_buildPlan(existing: existing));
      } else {
        await repo.createPlan(_buildPlan(), householdId);
      }

      await refreshPlansData(ref);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = ApiErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEdit) {
      final planAsync = ref.watch(planProvider(widget.planId!));
      planAsync.whenData((plan) {
        if (plan != null) _loadPlan(plan);
      });
      if (!_loaded) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_isEdit ? AppStrings.editPlan : AppStrings.addPlan),
          ),
          body: planAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppStrings.errorGeneric),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(planProvider(widget.planId!)),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            ),
            data: (plan) {
              if (plan == null) {
                return Center(child: Text(AppStrings.errorGeneric));
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        );
      }
    }

    final rosterAsync = ref.watch(familyRosterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? AppStrings.editPlan : AppStrings.addPlan),
      ),
      body: FormScreenBody(
        formKey: _formKey,
        children: [
          AppTextField(
            controller: _title,
            label: AppStrings.planTitle,
            validator: Validators.required,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: kFormFieldSpacing),
          AppTextField(
            controller: _description,
            label: AppStrings.planDescription,
            maxLines: 3,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: kFormFieldSpacing),
          DropdownButtonFormField<String>(
            value: _planType,
            decoration: const InputDecoration(labelText: AppStrings.planType),
            items: PlanTypes.all
                .map(
                  (t) => DropdownMenuItem(
                    value: t.value,
                    child: Text(t.label),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _planType = v;
                if (v == PlanTypes.meal) {
                  _mealSlot ??= MealSlots.lunch;
                  _dueAt ??= MealSlots.defaultDueAtForSlot(_mealSlot!);
                } else {
                  _mealSlot = null;
                }
              });
            },
          ),
          if (_planType == PlanTypes.meal) ...[
            const SizedBox(height: kFormFieldSpacing),
            Text(
              AppStrings.mealSlot,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MealSlots.primary.map((slot) {
                final selected = _mealSlot == slot;
                return ChoiceChip(
                  label: Text(MealSlots.labelFor(slot)),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _mealSlot = slot;
                      _error = null;
                      if (_dueAt == null) {
                        _dueAt = MealSlots.defaultDueAtForSlot(slot);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: kFormFieldSpacing),
          DropdownButtonFormField<String>(
            value: _scope,
            decoration: const InputDecoration(labelText: AppStrings.planScope),
            items: PlanScopes.all
                .map(
                  (s) => DropdownMenuItem(
                    value: s.value,
                    child: Text(s.label),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _scope = v);
            },
          ),
          const SizedBox(height: kFormFieldSpacing),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.dueDate),
            subtitle: Text(
              _dueAt != null
                  ? Formatters.dateTime(_dueAt!.toLocal())
                  : AppStrings.tapToSetDateTime,
            ),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: _pickDueDate,
          ),
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
          rosterAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => FormAsyncFieldError(
              message: AppStrings.rosterLoadError,
              onRetry: () => ref.invalidate(familyRosterProvider),
            ),
            data: (roster) {
              if (roster.isEmpty) return const SizedBox.shrink();
              return Column(
                children: [
                  const SizedBox(height: kFormFieldSpacing),
                  DropdownButtonFormField<String?>(
                    value: _aboutMemberId,
                    decoration:
                        const InputDecoration(labelText: AppStrings.forMember),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text(AppStrings.none),
                      ),
                      ...roster.map(
                        (m) => DropdownMenuItem(
                          value: m.id,
                          child: Text(m.listLabel),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _aboutMemberId = v),
                  ),
                  const SizedBox(height: kFormFieldSpacing),
                  DropdownButtonFormField<String?>(
                    value: _assignedToId,
                    decoration: const InputDecoration(
                      labelText: AppStrings.assignedTo,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text(AppStrings.none),
                      ),
                      ...roster.map(
                        (m) => DropdownMenuItem(
                          value: m.id,
                          child: Text(m.listLabel),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _assignedToId = v),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          FormSaveSection(
            error: _error,
            saveLabel: AppStrings.save,
            isLoading: _loading,
            onSave: _submit,
          ),
        ],
      ),
    );
  }
}
