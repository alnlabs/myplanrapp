import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/subscription_constants.dart';
import '../../../shared/models/subscription.dart';
import '../../../shared/providers/record_permissions.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/offline_guard.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/form_screen_body.dart';
import '../../../shared/widgets/reminder_field.dart';
import '../../auth/data/auth_repository.dart';
import '../../expenses/presentation/add_expense_screen.dart';
import '../data/subscription_repository.dart';

class SubscriptionFormScreen extends ConsumerStatefulWidget {
  const SubscriptionFormScreen({super.key, this.subscriptionId});

  final String? subscriptionId;

  @override
  ConsumerState<SubscriptionFormScreen> createState() =>
      _SubscriptionFormScreenState();
}

class _SubscriptionFormScreenState extends ConsumerState<SubscriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  final _paymentDetail = TextEditingController();

  String _billingCycle = BillingCycles.monthly;
  String? _paymentMethod;
  int _dueDay = 1;
  int _dueMonth = DateTime.now().month;
  bool _autoRenew = true;
  bool _reminderEnabled = false;
  DateTime? _reminderAt;
  int _reminderDaysBefore = 3;
  bool _loading = false;
  bool _loaded = false;
  String? _error;
  String? _reminderError;
  String? _householdId;

  bool get _isEdit => widget.subscriptionId != null;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _notes.dispose();
    _paymentDetail.dispose();
    super.dispose();
  }

  void _load(Subscription sub) {
    if (_loaded) return;
    _name.text = sub.name;
    _amount.text = sub.amount?.toString() ?? '';
    _notes.text = sub.notes ?? '';
    _paymentMethod = sub.paymentMethod;
    _paymentDetail.text = sub.paymentDetail ?? '';
    _billingCycle = sub.billingCycle;
    _dueDay = sub.dueDay;
    _dueMonth = sub.dueMonth ?? DateTime.now().month;
    _autoRenew = sub.autoRenew;
    _reminderEnabled = sub.reminderEnabled;
    _reminderAt = sub.reminderAt ?? sub.effectiveReminderAt;
    _reminderDaysBefore = sub.reminderDaysBefore;
    _householdId = sub.householdId;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  int _reminderDaysBeforeForSave() {
    if (!_reminderEnabled || _reminderAt == null) return _reminderDaysBefore;
    final due = Subscription.computeNextDueDate(
      billingCycle: _billingCycle,
      dueDay: _dueDay,
      dueMonth: _billingCycle == BillingCycles.yearly ? _dueMonth : null,
      from: DateTime.now(),
    );
    return DateTime(due.year, due.month, due.day)
        .difference(
          DateTime(_reminderAt!.year, _reminderAt!.month, _reminderAt!.day),
        )
        .inDays
        .clamp(0, 30);
  }

  Subscription _build({Subscription? existing}) {
    return Subscription(
      id: existing?.id ?? '',
      householdId: existing?.householdId ?? _householdId ?? '',
      createdBy: existing?.createdBy,
      name: _name.text.trim(),
      amount: double.tryParse(_amount.text.trim()),
      billingCycle: _billingCycle,
      dueDay: _dueDay,
      dueMonth: _billingCycle == BillingCycles.yearly ? _dueMonth : null,
      autoRenew: _autoRenew,
      reminderEnabled: _reminderEnabled,
      reminderDaysBefore: _reminderDaysBeforeForSave(),
      reminderAt: _reminderEnabled ? _reminderAt : null,
      notes: _emptyToNull(_notes.text),
      paymentMethod: _paymentMethod,
      paymentDetail: _paymentMethod == null
          ? null
          : _emptyToNull(_paymentDetail.text),
      isActive: existing?.isActive ?? true,
    );
  }

  String? _emptyToNull(String v) => v.trim().isEmpty ? null : v.trim();

  Future<void> _logPaymentAsExpense() async {
    if (!_isEdit || widget.subscriptionId == null) return;
    try {
      ref.ensureOnline();
      final sub = await ref
          .read(subscriptionRepositoryProvider)
          .fetchSubscription(widget.subscriptionId!);
      if (sub == null || !mounted) return;
      final updated = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => AddExpenseScreen(
            initialTitle: sub.name,
            initialAmount: sub.amount,
            sourceSubscriptionId: sub.id,
          ),
        ),
      );
      if (updated == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.saved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorFormatter.format(e))),
        );
      }
    }
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
      final profile = await ref.read(userProfileProvider.future);
      final householdId = profile?.activeHouseholdId;
      if (householdId == null) throw Exception(AppStrings.noHousehold);

      final repo = ref.read(subscriptionRepositoryProvider);
      if (_isEdit) {
        final existing = await repo.fetchSubscription(widget.subscriptionId!);
        if (existing == null) throw Exception(AppStrings.errorGeneric);
        await repo.updateSubscription(_build(existing: existing));
      } else {
        await repo.createSubscription(_build(), householdId);
      }

      ref.invalidate(subscriptionsProvider);
      ref.invalidate(subscriptionsDueSoonProvider);
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = ApiErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteSubscription),
        content: const Text(AppStrings.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(subscriptionRepositoryProvider)
          .deleteSubscription(widget.subscriptionId!);
      ref.invalidate(subscriptionsProvider);
      ref.invalidate(subscriptionsDueSoonProvider);
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = ApiErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = ref.watch(isHouseholdOwnerProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    Subscription? existing;
    if (_isEdit) {
      existing = ref.watch(subscriptionProvider(widget.subscriptionId!)).valueOrNull;
      ref.watch(subscriptionProvider(widget.subscriptionId!)).whenData((sub) {
        if (sub != null) _load(sub);
      });
    }

    final canDelete = existing != null &&
        canManageRecord(
          createdBy: existing.createdBy,
          currentUserId: currentUserId,
          isOwner: isOwner,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? AppStrings.editSubscription : AppStrings.addSubscription,
        ),
        actions: [
          if (_isEdit && canDelete)
            IconButton(
              onPressed: _loading ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: _isEdit && !_loaded
          ? ref.watch(subscriptionProvider(widget.subscriptionId!)).when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(AppStrings.errorGeneric),
                      TextButton(
                        onPressed: () => ref.invalidate(
                          subscriptionProvider(widget.subscriptionId!),
                        ),
                        child: const Text(AppStrings.retry),
                      ),
                    ],
                  ),
                ),
                data: (sub) {
                  if (sub == null) {
                    return Center(child: Text(AppStrings.errorGeneric));
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              )
          : FormScreenBody(
              formKey: _formKey,
              children: [
                AppTextField(
                  controller: _name,
                  label: AppStrings.subscriptionName,
                  validator: Validators.required,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: kFormFieldSpacing),
                AppTextField(
                  controller: _amount,
                  label: AppStrings.subscriptionAmount,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: kFormFieldSpacing),
                DropdownButtonFormField<String>(
                  value: _billingCycle,
                  decoration: const InputDecoration(
                    labelText: AppStrings.billingCycle,
                  ),
                  items: BillingCycles.all
                      .map((c) => DropdownMenuItem(
                            value: c.value,
                            child: Text(c.label),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _billingCycle = v!),
                ),
                const SizedBox(height: kFormFieldSpacing),
                DropdownButtonFormField<int>(
                  value: _dueDay,
                  decoration:
                      const InputDecoration(labelText: AppStrings.dueDay),
                  items: List.generate(
                    31,
                    (i) =>
                        DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                  ),
                  onChanged: (v) => setState(() => _dueDay = v!),
                ),
                if (_billingCycle == BillingCycles.yearly) ...[
                  const SizedBox(height: kFormFieldSpacing),
                  DropdownButtonFormField<int>(
                    value: _dueMonth,
                    decoration:
                        const InputDecoration(labelText: AppStrings.dueMonth),
                    items: List.generate(
                      12,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child:
                            Text(Formatters.monthYear(DateTime(2000, i + 1))),
                      ),
                    ),
                    onChanged: (v) => setState(() => _dueMonth = v!),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  AppStrings.paymentInfo,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: _paymentMethod,
                  decoration: const InputDecoration(
                    labelText: AppStrings.paymentMethod,
                    helperText: AppStrings.paymentMethodHint,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text(AppStrings.paymentMethodNotSet),
                    ),
                    ...PaymentMethods.all.map(
                      (method) => DropdownMenuItem<String?>(
                        value: method.value,
                        child: Text(method.label),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _paymentMethod = value;
                    if (value == null) _paymentDetail.clear();
                  }),
                ),
                if (_paymentMethod != null) ...[
                  const SizedBox(height: kFormFieldSpacing),
                  AppTextField(
                    controller: _paymentDetail,
                    label: AppStrings.paymentDetail,
                    helperText: PaymentMethods.detailHintFor(_paymentMethod),
                    textInputAction: TextInputAction.next,
                  ),
                ],
                const SizedBox(height: kFormFieldSpacing),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(AppStrings.autoRenew),
                  value: _autoRenew,
                  onChanged: (v) => setState(() => _autoRenew = v),
                ),
                ReminderField(
                  enabled: _reminderEnabled,
                  reminderAt: _reminderAt,
                  subtitle: AppStrings.subscriptionReminderHint,
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
                const SizedBox(height: kFormFieldSpacing),
                AppTextField(
                  controller: _notes,
                  label: AppStrings.notes,
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                if (_isEdit)
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _logPaymentAsExpense,
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text(AppStrings.logPaymentAsExpense),
                  ),
                if (_isEdit) const SizedBox(height: 16),
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
