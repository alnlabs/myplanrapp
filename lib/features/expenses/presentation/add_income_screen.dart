import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/models/expense.dart';
import '../../../shared/models/family_member.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/utils/offline_guard.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/form_error_banner.dart';
import '../../../shared/widgets/form_screen_body.dart';
import '../../auth/data/auth_repository.dart';
import '../../household/data/family_repository.dart';
import '../data/expense_repository.dart';
import '../data/recurring_money_rule_repository.dart';
import '../utils/income_form_validators.dart';

class AddIncomeScreen extends ConsumerStatefulWidget {
  const AddIncomeScreen({
    super.key,
    this.income,
    this.initialFamilyMemberId,
    this.initialIncomeSource,
    this.initialAmount,
    this.initialCategoryId,
    this.recurringRuleId,
  });

  final Expense? income;
  final String? initialFamilyMemberId;
  final String? initialIncomeSource;
  final double? initialAmount;
  final String? initialCategoryId;
  final String? recurringRuleId;

  bool get isEditing => income != null;

  @override
  ConsumerState<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends ConsumerState<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _incomeSource = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  String? _categoryId;
  String? _familyMemberId;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final income = widget.income;
    if (income != null) {
      _incomeSource.text = income.displaySource;
      _amount.text = income.amount.toString();
      _note.text = income.note ?? '';
      _date = income.expenseDate;
      _categoryId = income.categoryId;
      _familyMemberId = income.familyMemberId;
    } else {
      if (widget.initialIncomeSource != null) {
        _incomeSource.text = widget.initialIncomeSource!;
      }
      if (widget.initialAmount != null) {
        _amount.text = widget.initialAmount!.toString();
      }
      _familyMemberId = widget.initialFamilyMemberId;
      _categoryId = widget.initialCategoryId;
    }
  }

  @override
  void dispose() {
    _incomeSource.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final memberError = validateIncomeMemberId(_familyMemberId);
    if (memberError != null) {
      setState(() => _error = memberError);
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

      final repo = ref.read(expenseRepositoryProvider);
      if (widget.isEditing) {
        await repo.updateIncome(
          id: widget.income!.id,
          categoryId: _categoryId!,
          amount: double.parse(_amount.text.trim()),
          familyMemberId: _familyMemberId!,
          incomeSource: _incomeSource.text.trim(),
          incomeDate: _date,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        );
      } else {
        await repo.createIncome(
          householdId: householdId,
          categoryId: _categoryId!,
          amount: double.parse(_amount.text.trim()),
          familyMemberId: _familyMemberId!,
          incomeSource: _incomeSource.text.trim(),
          incomeDate: _date,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          recurringRuleId: widget.recurringRuleId,
        );
        if (widget.recurringRuleId != null) {
          await ref
              .read(recurringMoneyRuleRepositoryProvider)
              .advanceRule(widget.recurringRuleId!);
          ref.invalidate(memberRecurringIncomeProvider(_familyMemberId!));
          ref.invalidate(dueRecurringIncomeProvider);
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = ApiErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(incomeCategoriesProvider);
    final rosterAsync = ref.watch(familyRosterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? AppStrings.editIncome : AppStrings.addIncome,
        ),
      ),
      body: FormScreenBody(
        formKey: _formKey,
        children: [
          rosterAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => FormAsyncFieldError(
              message: AppStrings.errorGeneric,
              onRetry: () => ref.invalidate(familyRosterProvider),
            ),
            data: (members) {
              if (_familyMemberId == null && members.isNotEmpty) {
                _familyMemberId = widget.initialFamilyMemberId ?? members.first.id;
              }
              return DropdownButtonFormField<String>(
                value: _familyMemberId,
                decoration:
                    const InputDecoration(labelText: AppStrings.incomeMember),
                items: members
                    .map(
                      (FamilyMember m) => DropdownMenuItem(
                        value: m.id,
                        child: Text(m.listLabel),
                      ),
                    )
                    .toList(),
                validator: (_) => validateIncomeMemberId(_familyMemberId),
                onChanged: widget.isEditing
                    ? null
                    : (v) => setState(() => _familyMemberId = v),
              );
            },
          ),
          const SizedBox(height: kFormFieldSpacing),
          AppTextField(
            controller: _incomeSource,
            label: AppStrings.incomeSource,
            helperText: AppStrings.incomeSourceHint,
            validator: Validators.required,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: kFormFieldSpacing),
          AppTextField(
            controller: _amount,
            label: AppStrings.amount,
            prefixText: '₹ ',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: Validators.positiveAmount,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: kFormFieldSpacing),
          categoriesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => FormAsyncFieldError(
              message: AppStrings.categoriesLoadError,
              onRetry: () => ref.invalidate(incomeCategoriesProvider),
            ),
            data: (categories) {
              if (_categoryId == null) {
                for (final c in categories) {
                  if (c.name == 'Salary') {
                    _categoryId = c.id;
                    break;
                  }
                }
                _categoryId ??=
                    categories.isNotEmpty ? categories.first.id : null;
              }
              return DropdownButtonFormField<String>(
                value: _categoryId,
                decoration:
                    const InputDecoration(labelText: AppStrings.incomeCategory),
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
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.incomeDate),
            subtitle: Text(Formatters.date(_date)),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _date = picked);
            },
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
