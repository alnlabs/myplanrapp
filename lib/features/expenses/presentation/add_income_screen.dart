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
import 'scope_selector.dart';

class AddIncomeScreen extends ConsumerStatefulWidget {
  const AddIncomeScreen({
    super.key,
    this.income,
    this.initialFamilyMemberId,
    this.initialIncomeSource,
    this.initialAmount,
    this.initialCategoryId,
    this.initialScope,
    this.recurringRuleId,
  });

  final Expense? income;
  final String? initialFamilyMemberId;
  final String? initialIncomeSource;
  final double? initialAmount;
  final String? initialCategoryId;
  final MoneyScope? initialScope;
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
  MoneyScope _scope = MoneyScope.household;
  bool _loading = false;
  String? _error;

  bool _recurring = false;
  String _frequency = 'monthly';
  late int _dayOfMonth;

  /// New income added from the generic "Add income" flow is always recorded
  /// for the logged-in user, so we hide the member picker and lock it.
  bool get _lockToCurrentUser =>
      !widget.isEditing && widget.initialFamilyMemberId == null;

  /// The recurring option only makes sense when creating a brand-new income
  /// entry (not when editing or logging an already-due recurring rule).
  bool get _canOfferRecurring =>
      !widget.isEditing && widget.recurringRuleId == null;

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
      _scope = income.scope;
    } else {
      if (widget.initialIncomeSource != null) {
        _incomeSource.text = widget.initialIncomeSource!;
      }
      if (widget.initialAmount != null) {
        _amount.text = widget.initialAmount!.toString();
      }
      _familyMemberId = widget.initialFamilyMemberId;
      _categoryId = widget.initialCategoryId;
      _scope = widget.initialScope ?? MoneyScope.household;
    }
    _dayOfMonth = _date.day;
  }

  DateTime _nextRecurringDueDate() {
    switch (_frequency) {
      case 'weekly':
        return _date.add(const Duration(days: 7));
      case 'yearly':
        return DateTime(_date.year + 1, _date.month, _date.day);
      case 'monthly':
      default:
        var year = _date.year;
        var month = _date.month + 1;
        if (month > 12) {
          month = 1;
          year++;
        }
        final lastDay = DateTime(year, month + 1, 0).day;
        final day = _dayOfMonth > lastDay ? lastDay : _dayOfMonth;
        return DateTime(year, month, day);
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
          scope: _scope,
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
          scope: _scope,
        );
        if (widget.recurringRuleId != null) {
          await ref
              .read(recurringMoneyRuleRepositoryProvider)
              .advanceRule(widget.recurringRuleId!);
          ref.invalidate(memberRecurringIncomeProvider(_familyMemberId!));
          ref.invalidate(dueRecurringIncomeProvider);
        } else if (_recurring) {
          await ref.read(recurringMoneyRuleRepositoryProvider).createIncomeRule(
                householdId: householdId,
                familyMemberId: _familyMemberId!,
                incomeSource: _incomeSource.text.trim(),
                categoryId: _categoryId!,
                amount: double.parse(_amount.text.trim()),
                frequency: _frequency,
                startDate: _date,
                nextDueDate: _nextRecurringDueDate(),
                dayOfMonth: _frequency == 'monthly' ? _dayOfMonth : null,
                note: _note.text.trim().isEmpty ? null : _note.text.trim(),
                scope: _scope,
              );
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
          _buildMemberField(rosterAsync),
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
          const SizedBox(height: kFormFieldSpacing),
          ScopeSelector(
            scope: _scope,
            onChanged: (value) => setState(() => _scope = value),
          ),
          if (_canOfferRecurring) ...[
            const SizedBox(height: kFormFieldSpacing),
            _buildRecurringSection(context),
          ],
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

  Widget _buildMemberField(AsyncValue<List<FamilyMember>> rosterAsync) {
    if (_lockToCurrentUser) {
      final currentMemberAsync = ref.watch(currentUserFamilyMemberProvider);
      final locked = currentMemberAsync.maybeWhen(
        data: (member) => member,
        orElse: () => null,
      );
      if (locked != null) {
        _familyMemberId = locked.id;
        return InputDecorator(
          decoration: const InputDecoration(
            labelText: AppStrings.incomeForLabel,
          ),
          child: Text('${locked.listLabel} (${AppStrings.you})'),
        );
      }
      if (currentMemberAsync.isLoading) {
        return const LinearProgressIndicator();
      }
      // Fall back to the roster picker if we cannot resolve the current user.
    }

    return rosterAsync.when(
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
    );
  }

  Widget _buildRecurringSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _recurring,
          title: const Text(AppStrings.recurringIncomeToggle),
          subtitle: const Text(AppStrings.recurringIncomeToggleHint),
          onChanged: (v) => setState(() => _recurring = v),
        ),
        if (_recurring) ...[
          const SizedBox(height: kFormFieldSpacing),
          DropdownButtonFormField<String>(
            value: _frequency,
            decoration:
                const InputDecoration(labelText: AppStrings.frequencyLabel),
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
            onChanged: (v) {
              if (v != null) setState(() => _frequency = v);
            },
          ),
          if (_frequency == 'monthly') ...[
            const SizedBox(height: kFormFieldSpacing),
            DropdownButtonFormField<int>(
              value: _dayOfMonth,
              decoration:
                  const InputDecoration(labelText: AppStrings.dayOfMonthLabel),
              items: List.generate(
                31,
                (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text('${i + 1}'),
                ),
              ),
              onChanged: (v) {
                if (v != null) setState(() => _dayOfMonth = v);
              },
            ),
          ],
        ],
      ],
    );
  }
}
