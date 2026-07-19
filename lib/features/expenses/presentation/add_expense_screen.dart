import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/models/expense.dart';
import '../../../shared/models/pantry_item.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/offline_guard.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/form_error_banner.dart';
import '../../../shared/widgets/form_screen_body.dart';
import '../../../shared/widgets/quantity_with_unit_field.dart';
import '../../auth/data/auth_repository.dart';
import '../../pantry/data/pantry_repository.dart';
import '../../pantry/data/pantry_shop_refresh.dart';
import '../../subscriptions/data/subscription_repository.dart';
import '../data/expense_groups_repository.dart';
import '../data/expense_repository.dart';
import '../data/recurring_money_rule_repository.dart';
import 'expense_group_fields.dart';
import 'scope_selector.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({
    super.key,
    this.expense,
    this.initialTitle,
    this.initialAmount,
    this.initialCategoryId,
    this.initialGroupId,
    this.initialPaidByMemberId,
    this.initialScope,
    this.recurringRuleId,
    this.sourceSubscriptionId,
  });

  final Expense? expense;
  final String? initialTitle;
  final double? initialAmount;
  final String? initialCategoryId;
  final String? initialGroupId;
  final String? initialPaidByMemberId;
  final MoneyScope? initialScope;
  final String? recurringRuleId;
  final String? sourceSubscriptionId;

  bool get isEditing => expense != null;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupFieldsKey = GlobalKey<ExpenseGroupFieldsState>();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  String? _categoryId;
  MoneyScope _scope = MoneyScope.household;
  bool _linkPantry = false;
  PantryItem? _pantryItem;
  bool _creatingNewItem = false;
  final _restockQty = TextEditingController();
  final _newItemName = TextEditingController();
  String _newItemUnit = 'kg';
  bool _loading = false;
  String? _error;

  static const _newItemValue = '__new__';

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    if (expense != null) {
      _title.text = expense.title;
      _amount.text = expense.amount.toString();
      _note.text = expense.note ?? '';
      _date = expense.expenseDate;
      _categoryId = expense.categoryId;
      _scope = expense.scope;
    } else {
      if (widget.initialTitle != null) _title.text = widget.initialTitle!;
      if (widget.initialAmount != null) {
        _amount.text = widget.initialAmount.toString();
      }
      _categoryId = widget.initialCategoryId;
      _scope = widget.initialScope ?? MoneyScope.household;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    _restockQty.dispose();
    _newItemName.dispose();
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

      final repo = ref.read(expenseRepositoryProvider);
      final amount = double.parse(_amount.text.trim());
      final groupState = _groupFieldsKey.currentState;
      final groupId = groupState?.groupId;
      final paidByMemberId = groupState?.paidByMemberId;
      final splits = groupState?.buildSplits(amount);

      if (groupId != null) {
        final group = await ref.read(expenseGroupProvider(groupId).future);
        if (group?.isShared == true &&
            (splits == null || splits.length < 2)) {
          setState(() => _error = AppStrings.splitSumMismatch);
          return;
        }
      }

      if (widget.isEditing) {
        if (groupId != null) {
          await repo.updateExpenseWithSplits(
            id: widget.expense!.id,
            categoryId: _categoryId!,
            amount: amount,
            title: _title.text.trim(),
            expenseDate: _date,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            groupId: groupId,
            paidByMemberId: paidByMemberId,
            splits: splits ?? const [],
          );
        } else {
          await repo.updateExpense(
            id: widget.expense!.id,
            categoryId: _categoryId!,
            amount: amount,
            title: _title.text.trim(),
            expenseDate: _date,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            scope: _scope,
          );
        }
      } else {
        String? pantryItemId;
        double? restockDelta;

        if (_linkPantry) {
          final qtyText = _restockQty.text.trim();
          restockDelta = qtyText.isNotEmpty ? double.parse(qtyText) : null;

          if (_creatingNewItem) {
            final created =
                await ref.read(pantryRepositoryProvider).createItem(
                      PantryItem(
                        id: '',
                        householdId: householdId,
                        name: _newItemName.text.trim(),
                        quantity: 0,
                        unit: _newItemUnit,
                      ),
                      householdId,
                    );
            pantryItemId = created.id;
          } else {
            pantryItemId = _pantryItem?.id;
          }
        }

        if (groupId != null) {
          await repo.createExpenseWithSplits(
            householdId: householdId,
            categoryId: _categoryId!,
            amount: amount,
            title: _title.text.trim(),
            expenseDate: _date,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            groupId: groupId,
            paidByMemberId: paidByMemberId,
            splits: splits ?? const [],
          );
        } else {
          final created = await repo.createExpense(
            householdId: householdId,
            categoryId: _categoryId!,
            amount: amount,
            title: _title.text.trim(),
            expenseDate: _date,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            pantryItemId: pantryItemId,
            restockDelta: pantryItemId != null ? restockDelta : null,
            restockNote: _linkPantry ? 'Grocery purchase' : null,
            recurringRuleId: widget.recurringRuleId,
            sourceSubscriptionId: widget.sourceSubscriptionId,
            isRecurringInstance: widget.recurringRuleId != null,
            scope: _scope,
          );
          if (widget.sourceSubscriptionId != null) {
            await ref.read(subscriptionRepositoryProvider).linkLastPaidExpense(
                  widget.sourceSubscriptionId!,
                  created.id,
                );
            ref.invalidate(subscriptionsProvider);
          }
        }
        if (widget.recurringRuleId != null) {
          await ref
              .read(recurringMoneyRuleRepositoryProvider)
              .advanceRule(widget.recurringRuleId!);
          ref.invalidate(dueRecurringExpenseProvider);
          ref.invalidate(recurringExpenseRulesProvider);
        }
        if (_linkPantry) {
          await refreshPantryAfterStockChange(ref);
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
    final categoriesAsync = ref.watch(expenseCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? AppStrings.editExpense : AppStrings.addExpense),
      ),
      body: FormScreenBody(
        formKey: _formKey,
        children: [
          AppTextField(
            controller: _title,
            label: AppStrings.expenseTitle,
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
              onRetry: () => ref.invalidate(expenseCategoriesProvider),
            ),
            data: (categories) {
              if (_categoryId == null) {
                for (final c in categories) {
                  if (c.name == 'Groceries') {
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
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.expenseDate),
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
          ExpenseGroupFields(
            key: _groupFieldsKey,
            amountController: _amount,
            initialGroupId: widget.expense?.groupId ?? widget.initialGroupId,
            initialPaidByMemberId:
                widget.expense?.paidByMemberId ?? widget.initialPaidByMemberId,
            initialParticipantIds: widget.expense?.splits
                .map((s) => s.groupMemberId)
                .toSet(),
            initialSplits: widget.expense?.splits,
            // Rebuild so the "Link to Pantry" option hides as soon as a group
            // is selected (pantry restock doesn't apply to group expenses).
            onChanged: () {
              if (!mounted) return;
              setState(() {
                if (_groupFieldsKey.currentState?.groupId != null) {
                  _linkPantry = false;
                }
              });
            },
          ),
          // Visibility (Personal/Household) doesn't apply to group expenses;
          // those are shared with the group's members instead.
          if (_groupFieldsKey.currentState?.groupId == null) ...[
            const SizedBox(height: kFormFieldSpacing),
            ScopeSelector(
              scope: _scope,
              onChanged: (value) => setState(() => _scope = value),
            ),
          ],
          const SizedBox(height: kFormFieldSpacing),
          AppTextField(
            controller: _note,
            label: AppStrings.note,
            maxLines: 2,
          ),
          if (!widget.isEditing && _groupFieldsKey.currentState?.groupId == null) ...[
            const SizedBox(height: kFormFieldSpacing),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.linkToPantry),
              subtitle: const Text(AppStrings.linkToPantryHint),
              value: _linkPantry,
              onChanged: (v) => setState(() => _linkPantry = v),
            ),
            if (_linkPantry)
              _PantryLinkFields(
                creatingNewItem: _creatingNewItem,
                pantryItem: _pantryItem,
                newItemValue: _newItemValue,
                newItemNameController: _newItemName,
                restockQtyController: _restockQty,
                newItemUnit: _newItemUnit,
                onPantryItemChanged: (item, creatingNew) => setState(() {
                  _creatingNewItem = creatingNew;
                  _pantryItem = item;
                }),
                onUnitChanged: (unit) => setState(() => _newItemUnit = unit),
              ),
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
}

class _PantryLinkFields extends ConsumerWidget {
  const _PantryLinkFields({
    required this.creatingNewItem,
    required this.pantryItem,
    required this.newItemValue,
    required this.newItemNameController,
    required this.restockQtyController,
    required this.newItemUnit,
    required this.onPantryItemChanged,
    required this.onUnitChanged,
  });

  final bool creatingNewItem;
  final PantryItem? pantryItem;
  final String newItemValue;
  final TextEditingController newItemNameController;
  final TextEditingController restockQtyController;
  final String newItemUnit;
  final void Function(PantryItem? item, bool creatingNew) onPantryItemChanged;
  final ValueChanged<String> onUnitChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pantryAsync = ref.watch(pantryPickerItemsProvider);
    return pantryAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => FormAsyncFieldError(
        message: AppStrings.errorGeneric,
        onRetry: () => ref.invalidate(pantryPickerItemsProvider),
      ),
      data: (items) {
        final selectedValue =
            creatingNewItem ? newItemValue : pantryItem?.id;
        return Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedValue,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: AppStrings.pantryChooseItem,
              ),
              items: [
                ...items.map(
                  (i) => DropdownMenuItem(
                    value: i.id,
                    child: Text(
                      '${i.name} · ${Formatters.quantity(i.quantity, i.unit)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: newItemValue,
                  child: const Text(AppStrings.pantryCreateNew),
                ),
              ],
              onChanged: (v) {
                if (v == newItemValue) {
                  onPantryItemChanged(null, true);
                } else {
                  onPantryItemChanged(
                    items.where((i) => i.id == v).firstOrNull,
                    false,
                  );
                }
              },
            ),
            if (creatingNewItem) ...[
              const SizedBox(height: 12),
              AppTextField(
                controller: newItemNameController,
                label: AppStrings.newItemName,
                validator: Validators.required,
              ),
              const SizedBox(height: 12),
              QuantityWithUnitField(
                controller: restockQtyController,
                label: AppStrings.quantity,
                unit: newItemUnit,
                onUnitChanged: onUnitChanged,
                validator: Validators.positiveNumber,
              ),
            ] else if (pantryItem != null) ...[
              const SizedBox(height: 12),
              QuantityWithUnitField(
                controller: restockQtyController,
                label: AppStrings.restockItem,
                unit: pantryItem!.unit,
                readOnlyUnit: true,
                validator: Validators.positiveNumber,
              ),
            ],
          ],
        );
      },
    );
  }
}
