import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../expenses/data/expense_repository.dart';
import '../../expenses/data/recurring_money_rule_repository.dart';
import '../../expenses/presentation/add_income_screen.dart';

class RecurringIncomeSection extends ConsumerWidget {
  const RecurringIncomeSection({
    super.key,
    required this.familyMemberId,
    required this.householdId,
    required this.canEdit,
  });

  final String familyMemberId;
  final String householdId;
  final bool canEdit;

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final sourceController = TextEditingController();
    final amountController = TextEditingController();
    final categories = await ref.read(incomeCategoriesProvider.future);
    if (!context.mounted) return;
    var categoryId = categories
        .where((c) => c.name == 'Salary')
        .map((c) => c.id)
        .firstOrNull;
    categoryId ??= categories.isNotEmpty ? categories.first.id : null;
    var frequency = 'monthly';
    var dayOfMonth = DateTime.now().day;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(AppStrings.addRecurringIncome),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: sourceController,
                  label: AppStrings.incomeSource,
                  helperText: AppStrings.incomeSourceHint,
                  validator: Validators.required,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: amountController,
                  label: AppStrings.amount,
                  prefixText: '₹ ',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: categoryId,
                  decoration:
                      const InputDecoration(labelText: AppStrings.incomeCategory),
                  items: categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => categoryId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: frequency,
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
                  onChanged: (v) {
                    if (v != null) setDialogState(() => frequency = v);
                  },
                ),
                if (frequency == 'monthly') ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: dayOfMonth,
                    decoration: const InputDecoration(labelText: 'Day of month'),
                    items: List.generate(
                      31,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text('${i + 1}'),
                      ),
                    ),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => dayOfMonth = v);
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () {
                if (sourceController.text.trim().isEmpty ||
                    amountController.text.trim().isEmpty ||
                    categoryId == null) {
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );

    if (saved != true || categoryId == null) return;

    try {
      final now = DateTime.now();
      final nextDue = DateTime(now.year, now.month, dayOfMonth);
      await ref.read(recurringMoneyRuleRepositoryProvider).createIncomeRule(
            householdId: householdId,
            familyMemberId: familyMemberId,
            incomeSource: sourceController.text.trim(),
            categoryId: categoryId!,
            amount: double.parse(amountController.text.trim()),
            frequency: frequency,
            startDate: now,
            nextDueDate: nextDue.isBefore(now)
                ? DateTime(now.year, now.month + 1, dayOfMonth)
                : nextDue,
            dayOfMonth: frequency == 'monthly' ? dayOfMonth : null,
          );
      ref.invalidate(memberRecurringIncomeProvider(familyMemberId));
      ref.invalidate(dueRecurringIncomeProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.saved)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorFormatter.format(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(memberRecurringIncomeProvider(familyMemberId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.recurringIncome,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (canEdit)
                  TextButton.icon(
                    onPressed: () => _showAddDialog(context, ref),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(AppStrings.addRecurringIncome),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            rulesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Text(AppStrings.errorGeneric),
              data: (rules) {
                if (rules.isEmpty) {
                  return Text(
                    AppStrings.emptyIncome,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  );
                }
                return Column(
                  children: rules.map((rule) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(rule.displayLabel),
                      subtitle: Text(
                        '${AppStrings.nextDue}: ${Formatters.date(rule.nextDueDate)} · ${Formatters.currency(rule.amount)}',
                      ),
                      trailing: canEdit
                          ? IconButton(
                              icon: Icon(
                                rule.isActive ? Icons.pause : Icons.play_arrow,
                              ),
                              tooltip: rule.isActive
                                  ? AppStrings.pauseRecurring
                                  : AppStrings.resumeRecurring,
                              onPressed: () async {
                                await ref
                                    .read(recurringMoneyRuleRepositoryProvider)
                                    .setRuleActive(rule.id, !rule.isActive);
                                ref.invalidate(
                                  memberRecurringIncomeProvider(familyMemberId),
                                );
                              },
                            )
                          : null,
                      onTap: canEdit
                          ? () async {
                              final updated =
                                  await Navigator.of(context).push<bool>(
                                MaterialPageRoute<bool>(
                                  builder: (_) => AddIncomeScreen(
                                    initialFamilyMemberId: familyMemberId,
                                    initialIncomeSource: rule.incomeSource,
                                    initialAmount: rule.amount,
                                    initialCategoryId: rule.categoryId,
                                    recurringRuleId: rule.id,
                                  ),
                                ),
                              );
                              if (updated == true) {
                                ref.invalidate(
                                  memberRecurringIncomeProvider(familyMemberId),
                                );
                                ref.invalidate(dueRecurringIncomeProvider);
                              }
                            }
                          : null,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
