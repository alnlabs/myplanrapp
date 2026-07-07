import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../../shared/models/expense.dart';
import '../../../shared/providers/record_permissions.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../data/expense_repository.dart';
import 'add_expense_screen.dart';
import 'expense_summary_screen.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final summaryAsync = ref.watch(expenseSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.expensesTitle),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ExpenseSummaryScreen(),
              ),
            ),
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: AppStrings.summaryTitle,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(expensesProvider);
          ref.invalidate(expenseSummaryProvider);
          await ref.read(expensesProvider.future);
        },
        child: AsyncScreenBody(
          value: expensesAsync,
          onRetry: () => ref.invalidate(expensesProvider),
          isEmpty: (items) => items.isEmpty,
          emptyIcon: Icons.payments_outlined,
          emptyTitle: AppStrings.emptyExpenses,
          emptySubtitle: AppStrings.emptyExpensesHint,
          emptyActionLabel: AppStrings.addExpense,
          onEmptyAction: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AddExpenseScreen()),
          ),
          builder: (expenses) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              summaryAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (rows) {
                  final total =
                      rows.fold<double>(0, (s, r) => s + r.totalAmount);
                  return _MonthlyTotalCard(total: total);
                },
              ),
              const SizedBox(height: 20),
              _ExpenseList(expenses: expenses),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AddExpenseScreen()),
          );
          ref.invalidate(expensesProvider);
          ref.invalidate(expenseSummaryProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addExpense),
      ),
    );
  }
}

class _MonthlyTotalCard extends StatelessWidget {
  const _MonthlyTotalCard({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.monthlyTotal,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(0.85),
                  ),
                ),
                Text(
                  Formatters.monthYear(DateTime.now()),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            Formatters.currency(total),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseList extends ConsumerWidget {
  const _ExpenseList({required this.expenses});

  final List<Expense> expenses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final isOwner = ref.watch(isHouseholdOwnerProvider);
    final memberNames = ref.watch(memberNamesProvider);
    final theme = Theme.of(context);

    final grouped = <String, List<Expense>>{};
    for (final expense in expenses) {
      final key = Formatters.date(expense.expenseDate);
      grouped.putIfAbsent(key, () => []).add(expense);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        final dayTotal =
            entry.value.fold<double>(0, (s, e) => s + e.amount);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    Formatters.currency(dayTotal),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            ...entry.value.map((expense) {
              final canEdit = canManageRecord(
                createdBy: expense.createdBy,
                currentUserId: currentUserId,
                isOwner: isOwner,
              );
              final creatorName = expense.createdBy != null
                  ? memberNames[expense.createdBy]
                  : null;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.receipt_long_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  title: Text(expense.title),
                  subtitle: Text(
                    [
                      if (expense.categoryName != null) expense.categoryName!,
                      if (creatorName != null) AppStrings.addedBy(creatorName),
                    ].join(' · '),
                  ),
                  trailing: Text(
                    Formatters.currency(expense.amount),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: canEdit
                      ? () async {
                          final updated =
                              await Navigator.of(context).push<bool>(
                            MaterialPageRoute<bool>(
                              builder: (_) =>
                                  AddExpenseScreen(expense: expense),
                            ),
                          );
                          if (updated == true) {
                            ref.invalidate(expensesProvider);
                            ref.invalidate(expenseSummaryProvider);
                          }
                        }
                      : null,
                  onLongPress: canEdit
                      ? () async {
                          final confirmed = await showConfirmDialog(
                            context,
                            title: AppStrings.delete,
                          );
                          if (confirmed != true) return;
                          await ref
                              .read(expenseRepositoryProvider)
                              .deleteExpense(expense.id);
                          ref.invalidate(expensesProvider);
                          ref.invalidate(expenseSummaryProvider);
                        }
                      : null,
                ),
              );
            }),
          ],
        );
      }).toList(),
    );
  }
}
