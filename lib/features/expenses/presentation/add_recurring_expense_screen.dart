import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/models/subscription.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/offline_guard.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/form_error_banner.dart';
import '../../../shared/widgets/form_screen_body.dart';
import '../../auth/data/auth_repository.dart';
import '../../subscriptions/data/subscription_repository.dart';
import '../data/expense_repository.dart';
import '../data/recurring_money_rule_repository.dart';
import '../utils/recurring_due_date.dart';

class AddRecurringExpenseScreen extends ConsumerStatefulWidget {
  const AddRecurringExpenseScreen({super.key});

  @override
  ConsumerState<AddRecurringExpenseScreen> createState() =>
      _AddRecurringExpenseScreenState();
}

class _AddRecurringExpenseScreenState
    extends ConsumerState<AddRecurringExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String? _categoryId;
  var _frequency = 'monthly';
  var _dayOfMonth = DateTime.now().day;
  var _autoLog = false;
  String? _subscriptionId;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      ref.ensureOnline();
      final profile = await ref.read(userProfileProvider.future);
      final householdId = profile?.activeHouseholdId;
      if (householdId == null) throw Exception(AppStrings.noHousehold);

      final now = DateTime.now();
      final nextDue = nextMonthlyRecurringDueDate(
        reference: now,
        dayOfMonth: _dayOfMonth,
      );
      await ref.read(recurringMoneyRuleRepositoryProvider).createExpenseRule(
            householdId: householdId,
            title: _title.text.trim(),
            categoryId: _categoryId!,
            amount: double.parse(_amount.text.trim()),
            frequency: _frequency,
            startDate: now,
            nextDueDate: nextDue,
            dayOfMonth: recurringDayOfMonthForFrequency(_frequency, _dayOfMonth),
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            autoLog: _autoLog,
            subscriptionId: _subscriptionId,
          );

      ref.invalidate(recurringExpenseRulesProvider);
      ref.invalidate(dueRecurringExpenseProvider);
      if (mounted) context.pop(true);
    } catch (e) {
      setState(() => _error = ApiErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(expenseCategoriesProvider);
    final subsAsync = ref.watch(subscriptionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.addRecurringExpense),
      ),
      body: FormScreenBody(
        formKey: _formKey,
        children: [
          AppTextField(
            controller: _title,
            label: AppStrings.expenseTitle,
            validator: Validators.required,
          ),
          const SizedBox(height: kFormFieldSpacing),
          AppTextField(
            controller: _amount,
            label: AppStrings.amount,
            prefixText: '₹ ',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: Validators.positiveAmount,
          ),
          const SizedBox(height: kFormFieldSpacing),
          categoriesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => FormAsyncFieldError(
              message: AppStrings.categoriesLoadError,
              onRetry: () => ref.invalidate(expenseCategoriesProvider),
            ),
            data: (categories) {
              _categoryId ??=
                  categories.isNotEmpty ? categories.first.id : null;
              return DropdownButtonFormField<String>(
                value: _categoryId,
                decoration:
                    const InputDecoration(labelText: AppStrings.category),
                items: categories
                    .map((c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                validator: Validators.category,
                onChanged: (v) => setState(() => _categoryId = v),
              );
            },
          ),
          const SizedBox(height: kFormFieldSpacing),
          DropdownButtonFormField<String>(
            value: _frequency,
            decoration: const InputDecoration(labelText: 'Frequency'),
            items: const [
              DropdownMenuItem(
                value: 'monthly',
                child: Text(AppStrings.frequencyMonthly),
              ),
              DropdownMenuItem(
                value: 'weekly',
                child: Text(AppStrings.frequencyWeekly),
              ),
              DropdownMenuItem(
                value: 'yearly',
                child: Text(AppStrings.frequencyYearly),
              ),
            ],
            onChanged: (v) => setState(() => _frequency = v ?? 'monthly'),
          ),
          if (_frequency == 'monthly') ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _dayOfMonth,
              decoration: const InputDecoration(labelText: AppStrings.dueDay),
              items: List.generate(
                31,
                (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
              ),
              onChanged: (v) {
                if (v != null) setState(() => _dayOfMonth = v);
              },
            ),
          ],
          const SizedBox(height: kFormFieldSpacing),
          subsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (subs) {
              if (subs.isEmpty) return const SizedBox.shrink();
              return DropdownButtonFormField<String?>(
                value: _subscriptionId,
                decoration: const InputDecoration(
                  labelText: AppStrings.linkedSubscription,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text(AppStrings.noGroup),
                  ),
                  ...subs.map(
                    (Subscription s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(s.name),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _subscriptionId = v),
              );
            },
          ),
          const SizedBox(height: kFormFieldSpacing),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.autoLogExpense),
            value: _autoLog,
            onChanged: (v) => setState(() => _autoLog = v),
          ),
          const SizedBox(height: kFormFieldSpacing),
          AppTextField(
            controller: _note,
            label: AppStrings.note,
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          FormSaveSection(
            error: _error,
            saveLabel: AppStrings.save,
            isLoading: _loading,
            onSave: _save,
          ),
        ],
      ),
    );
  }
}
