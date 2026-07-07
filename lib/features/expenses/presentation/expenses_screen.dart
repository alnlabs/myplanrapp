import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../../shared/models/expense.dart';
import '../../../shared/providers/record_permissions.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../../../shared/widgets/section_header.dart';
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/more'),
        ),
        title: const Text(AppStrings.expensesTitle),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ExpenseSummaryScreen(),
                ),
              );
            },
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: AppStrings.summaryTitle,
          ),
          IconButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AddExpenseScreen()),
              );
              ref.invalidate(expensesProvider);
              ref.invalidate(expenseSummaryProvider);
            },
            icon: const Icon(Icons.add),
            tooltip: AppStrings.addExpense,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(expensesProvider);
          ref.invalidate(expenseSummaryProvider);
          await ref.read(expensesProvider.future);
        },
        child: ListView(
          children: [
            summaryAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (rows) {
                final total = rows.fold<double>(0, (s, r) => s + r.totalAmount);
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: ListTile(
                      title: const Text(AppStrings.monthlyTotal),
                      subtitle: Text(Formatters.monthYear(DateTime.now())),
                      trailing: Text(
                        Formatters.currency(total),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                );
              },
            ),
            AsyncScreenBody(
              value: expensesAsync,
              onRetry: () => ref.invalidate(expensesProvider),
              isEmpty: (items) => items.isEmpty,
              emptyTitle: AppStrings.emptyExpenses,
              emptySubtitle: AppStrings.emptyExpensesHint,
              emptyActionLabel: AppStrings.addExpense,
              onEmptyAction: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AddExpenseScreen()),
              ),
              builder: (expenses) => _ExpenseList(expenses: expenses),
            ),
          ],
        ),
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
    final grouped = <String, List<Expense>>{};
    for (final expense in expenses) {
      final key = Formatters.date(expense.expenseDate);
      grouped.putIfAbsent(key, () => []).add(expense);
    }

    return Column(
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: entry.key),
            ...entry.value.map(
              (expense) {
                final canEdit = canManageRecord(
                  createdBy: expense.createdBy,
                  currentUserId: currentUserId,
                  isOwner: isOwner,
                );
                final creatorName = expense.createdBy != null
                    ? memberNames[expense.createdBy]
                    : null;
                return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(expense.title),
                  subtitle: Text(
                    [
                      if (expense.categoryName != null) expense.categoryName!,
                      if (creatorName != null) AppStrings.addedBy(creatorName),
                    ].join(' · '),
                  ),
                  trailing: Text(Formatters.currency(expense.amount)),
                  onTap: canEdit
                      ? () async {
                    final updated = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => AddExpenseScreen(expense: expense),
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
              },
            ),
          ],
        );
      }).toList(),
    );
  }
}
