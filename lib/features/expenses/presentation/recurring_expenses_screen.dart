import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../data/recurring_money_rule_repository.dart';
import 'add_expense_screen.dart';

class RecurringExpensesScreen extends ConsumerWidget {
  const RecurringExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(recurringExpenseRulesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.recurringExpenses)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/expenses/recurring/add'),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addRecurringExpense),
      ),
      body: AsyncScreenBody(
        value: rulesAsync,
        onRetry: () => ref.invalidate(recurringExpenseRulesProvider),
        isEmpty: (rules) => rules.isEmpty,
        emptyTitle: AppStrings.emptyRecurringExpenses,
        emptySubtitle: AppStrings.emptyRecurringExpensesHint,
        emptyActionLabel: AppStrings.addRecurringExpense,
        onEmptyAction: () => context.push('/expenses/recurring/add'),
        builder: (rules) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: rules.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final rule = rules[index];
            return Card(
              child: ListTile(
                leading: Icon(
                  rule.isActive ? Icons.event_repeat : Icons.pause_circle_outline,
                ),
                title: Text(
                  rule.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${AppStrings.nextDue}: ${Formatters.date(rule.nextDueDate)} · '
                  '${Formatters.currency(rule.amount)}'
                  '${rule.autoLog ? ' · auto' : ''}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: Icon(rule.isActive ? Icons.pause : Icons.play_arrow),
                  onPressed: () async {
                    await ref
                        .read(recurringMoneyRuleRepositoryProvider)
                        .setRuleActive(rule.id, !rule.isActive);
                    ref.invalidate(recurringExpenseRulesProvider);
                    ref.invalidate(dueRecurringExpenseProvider);
                  },
                ),
                onTap: () async {
                  final updated = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => AddExpenseScreen(
                        initialTitle: rule.title,
                        initialAmount: rule.amount,
                        initialCategoryId: rule.categoryId,
                        initialGroupId: rule.groupId,
                        initialPaidByMemberId: rule.paidByMemberId,
                        recurringRuleId: rule.id,
                        sourceSubscriptionId: rule.subscriptionId,
                      ),
                    ),
                  );
                  if (updated == true) {
                    ref.invalidate(recurringExpenseRulesProvider);
                    ref.invalidate(dueRecurringExpenseProvider);
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
