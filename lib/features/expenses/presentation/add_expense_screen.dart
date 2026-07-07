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
import '../../../shared/widgets/loading_button.dart';
import '../../auth/data/auth_repository.dart';
import '../../pantry/data/pantry_repository.dart';
import '../data/expense_repository.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, this.expense});

  final Expense? expense;

  bool get isEditing => expense != null;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  String? _categoryId;
  bool _linkPantry = false;
  PantryItem? _pantryItem;
  final _restockQty = TextEditingController();
  bool _loading = false;
  String? _error;

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
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    _restockQty.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      setState(() => _error = 'Please select a category');
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
        await repo.updateExpense(
          id: widget.expense!.id,
          categoryId: _categoryId!,
          amount: double.parse(_amount.text.trim()),
          title: _title.text.trim(),
          expenseDate: _date,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        );
      } else {
        await repo.createExpense(
            householdId: householdId,
            categoryId: _categoryId!,
            amount: double.parse(_amount.text.trim()),
            title: _title.text.trim(),
            expenseDate: _date,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            pantryItemId: _linkPantry ? _pantryItem?.id : null,
            restockDelta: _linkPantry && _restockQty.text.trim().isNotEmpty
                ? double.parse(_restockQty.text.trim())
                : null,
            restockNote: _linkPantry ? 'Grocery purchase' : null,
          );
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
    final pantryAsync = ref.watch(pantryItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? AppStrings.editExpense : AppStrings.addExpense),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _title,
                  label: AppStrings.expenseTitle,
                  validator: Validators.required,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _amount,
                  label: AppStrings.amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: Validators.positiveAmount,
                ),
                const SizedBox(height: 16),
                categoriesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (categories) {
                    if (_categoryId == null) {
                      for (final c in categories) {
                        if (c.name == 'Groceries') {
                          _categoryId = c.id;
                          break;
                        }
                      }
                      _categoryId ??= categories.isNotEmpty ? categories.first.id : null;
                    }
                    return DropdownButtonFormField<String>(
                      value: _categoryId,
                      decoration: const InputDecoration(labelText: AppStrings.category),
                      items: categories
                          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: (v) => setState(() => _categoryId = v),
                    );
                  },
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 8),
                AppTextField(controller: _note, label: AppStrings.note, maxLines: 2),
                if (!widget.isEditing) ...[
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(AppStrings.linkToPantry),
                    value: _linkPantry,
                    onChanged: (v) => setState(() => _linkPantry = v),
                  ),
                  if (_linkPantry)
                    pantryAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (items) {
                        return Column(
                          children: [
                            DropdownButtonFormField<PantryItem>(
                              value: _pantryItem,
                              decoration: const InputDecoration(labelText: AppStrings.pantryTitle),
                              items: items
                                  .map((i) => DropdownMenuItem(value: i, child: Text(i.name)))
                                  .toList(),
                              onChanged: (v) => setState(() => _pantryItem = v),
                            ),
                            const SizedBox(height: 12),
                            AppTextField(
                              controller: _restockQty,
                              label: AppStrings.restockItem,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ],
                        );
                      },
                    ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 24),
                LoadingButton(
                  label: AppStrings.save,
                  isLoading: _loading,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
