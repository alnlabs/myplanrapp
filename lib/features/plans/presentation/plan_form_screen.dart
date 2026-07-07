import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/plan_constants.dart';
import '../../../shared/models/plan.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/offline_guard.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../auth/data/auth_repository.dart';
import '../../household/data/family_repository.dart';
import '../data/plan_repository.dart';

class PlanFormScreen extends ConsumerStatefulWidget {
  const PlanFormScreen({super.key, this.planId});

  final String? planId;

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
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  bool get _isEdit => widget.planId != null;

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
    _loaded = true;
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueAt ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt ?? DateTime.now()),
    );
    if (time == null) return;
    setState(() {
      _dueAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickReminder() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderAt ?? _dueAt ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminderAt ?? DateTime.now()),
    );
    if (time == null) return;
    setState(() {
      _reminderAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _reminderEnabled = true;
    });
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
      completedAt: existing?.completedAt,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_reminderEnabled && _reminderAt == null) {
      setState(() => _error = 'Pick a reminder time');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
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

      ref.invalidate(plansProvider);
      ref.invalidate(openPlansProvider);
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
    }

    final rosterAsync = ref.watch(familyRosterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? AppStrings.editPlan : AppStrings.addPlan),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _title,
                  label: AppStrings.planTitle,
                  validator: Validators.required,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _description,
                  label: AppStrings.planDescription,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
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
                    if (v != null) setState(() => _planType = v);
                  },
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(AppStrings.dueDate),
                  subtitle: Text(
                    _dueAt?.toLocal().toString().substring(0, 16) ??
                        AppStrings.none,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today_outlined),
                    onPressed: _pickDueDate,
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(AppStrings.reminder),
                  value: _reminderEnabled,
                  onChanged: (v) => setState(() {
                    _reminderEnabled = v;
                    if (!v) _reminderAt = null;
                  }),
                ),
                if (_reminderEnabled)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(AppStrings.reminderAt),
                    subtitle: Text(
                      _reminderAt?.toLocal().toString().substring(0, 16) ??
                          'Tap to set',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.alarm_outlined),
                      onPressed: _pickReminder,
                    ),
                  ),
                rosterAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (roster) {
                    if (roster.isEmpty) return const SizedBox.shrink();
                    return Column(
                      children: [
                        const SizedBox(height: 8),
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
                                child: Text(m.displayName),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _aboutMemberId = v),
                        ),
                        const SizedBox(height: 16),
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
                                child: Text(m.displayName),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _assignedToId = v),
                        ),
                      ],
                    );
                  },
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
                  label: AppStrings.save,
                  isLoading: _loading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
