import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/models/expense_group.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/utils/offline_guard.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../data/expense_groups_repository.dart';
import '../utils/expense_split_calculator.dart';

class ExpenseSettlementScreen extends ConsumerStatefulWidget {
  const ExpenseSettlementScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<ExpenseSettlementScreen> createState() =>
      _ExpenseSettlementScreenState();
}

class _ExpenseSettlementScreenState extends ConsumerState<ExpenseSettlementScreen> {
  bool _recording = false;

  Future<void> _recordSettlement(SuggestedSettlement suggestion) async {
    setState(() => _recording = true);
    try {
      ref.ensureOnline();
      await ref.read(expenseGroupsRepositoryProvider).recordSettlement(
            groupId: widget.groupId,
            fromMemberId: suggestion.fromMemberId,
            toMemberId: suggestion.toMemberId,
            amount: suggestion.amount,
          );
      ref.invalidate(expenseGroupBalancesProvider(widget.groupId));
      if (mounted) {
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
    } finally {
      if (mounted) setState(() => _recording = false);
    }
  }

  Future<void> _recordManual(
    List<ExpenseGroupMember> members,
    List<ExpenseGroupBalance> balances,
  ) async {
    String? fromId;
    String? toId;
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(AppStrings.recordSettlement),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: fromId,
                  decoration:
                      const InputDecoration(labelText: AppStrings.settlementFrom),
                  items: members
                      .map(
                        (m) => DropdownMenuItem(
                          value: m.id,
                          child: Text(m.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => fromId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: toId,
                  decoration:
                      const InputDecoration(labelText: AppStrings.settlementTo),
                  items: members
                      .map(
                        (m) => DropdownMenuItem(
                          value: m.id,
                          child: Text(m.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => toId = v),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: amountController,
                  label: AppStrings.amount,
                  prefixText: '₹ ',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: Validators.positiveAmount,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: noteController,
                  label: AppStrings.note,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );

    if (saved != true || fromId == null || toId == null) return;
    if (fromId == toId) return;

    try {
      ref.ensureOnline();
      await ref.read(expenseGroupsRepositoryProvider).recordSettlement(
            groupId: widget.groupId,
            fromMemberId: fromId!,
            toMemberId: toId!,
            amount: double.parse(amountController.text.trim()),
            note: noteController.text.trim().isEmpty
                ? null
                : noteController.text.trim(),
          );
      ref.invalidate(expenseGroupBalancesProvider(widget.groupId));
      if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    final balancesAsync = ref.watch(expenseGroupBalancesProvider(widget.groupId));
    final membersAsync = ref.watch(expenseGroupMembersProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settlements)),
      floatingActionButton: balancesAsync.hasValue && membersAsync.hasValue
          ? FloatingActionButton.extended(
              onPressed: _recording
                  ? null
                  : () => _recordManual(
                        membersAsync.value!,
                        balancesAsync.value!,
                      ),
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.recordSettlement),
            )
          : null,
      body: AsyncScreenBody(
        value: balancesAsync,
        onRetry: () =>
            ref.invalidate(expenseGroupBalancesProvider(widget.groupId)),
        builder: (balances) {
          final suggestions =
              ExpenseSplitCalculator.suggestSettlements(balances);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                AppStrings.netBalance,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...balances.map(
                (b) => ListTile(
                  title: Text(b.displayName),
                  subtitle: Text(
                    '${AppStrings.moneySpent}: ${Formatters.currency(b.paidTotal)} · '
                    'owed: ${Formatters.currency(b.owedTotal)}',
                  ),
                  trailing: Text(Formatters.currency(b.netBalance)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.suggestedSettlements,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (suggestions.isEmpty)
                const Text(AppStrings.emptyExpenses)
              else
                ...suggestions.map(
                  (s) => Card(
                    child: ListTile(
                      title: Text('${s.fromName} → ${s.toName}'),
                      trailing: TextButton(
                        onPressed: _recording
                            ? null
                            : () => _recordSettlement(s),
                        child: Text(Formatters.currency(s.amount)),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
