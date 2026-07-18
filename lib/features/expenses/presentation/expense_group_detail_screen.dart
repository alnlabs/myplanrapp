import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/models/expense.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../data/expense_date_filter_provider.dart';
import '../data/expense_groups_repository.dart';
import '../../../shared/providers/paginated_list_state.dart';
import '../../../shared/widgets/paginated_list_footer.dart';
import 'expense_period_filter_bar.dart';

class ExpenseGroupDetailScreen extends ConsumerWidget {
  const ExpenseGroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(expenseGroupProvider(groupId));
    final membersAsync = ref.watch(expenseGroupMembersProvider(groupId));
    final balancesAsync = ref.watch(expenseGroupBalancesProvider(groupId));
    final range = ref.watch(expenseDateRangeProvider);
    final expensesState =
        ref.watch(expenseGroupExpensesProvider((groupId, range)));

    return Scaffold(
      appBar: AppBar(
        title: groupAsync.when(
          data: (g) => Text(g?.name ?? AppStrings.expenseGroupsTitle),
          loading: () => const Text(AppStrings.expenseGroupsTitle),
          error: (_, __) => const Text(AppStrings.expenseGroupsTitle),
        ),
        actions: [
          if (groupAsync.valueOrNull?.isShared == true)
            IconButton(
              onPressed: () => context.push('/expenses/groups/$groupId/settle'),
              icon: const Icon(Icons.balance_outlined),
              tooltip: AppStrings.settlements,
            ),
        ],
      ),
      body: AsyncScreenBody(
        value: groupAsync,
        onRetry: () => ref.invalidate(expenseGroupProvider(groupId)),
        builder: (group) {
          if (group == null) {
            return const Center(child: Text(AppStrings.errorGeneric));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(expenseGroupProvider(groupId));
              ref.invalidate(expenseGroupMembersProvider(groupId));
              ref.invalidate(expenseGroupBalancesProvider(groupId));
              await ref
                  .read(expenseGroupExpensesProvider((groupId, range)).notifier)
                  .refresh();
            },
            child: PaginatedScrollListener(
              onLoadMore: () => ref
                  .read(expenseGroupExpensesProvider((groupId, range)).notifier)
                  .loadMore(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    group.isShared
                        ? AppStrings.groupTypeShared
                        : AppStrings.groupTypeOrganizational,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 12),
                  const ExpensePeriodFilterBar(),
                  const SizedBox(height: 16),
                  if (group.isShared)
                    balancesAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (balances) => Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                AppStrings.netBalance,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            ...balances.map(
                              (b) => ListTile(
                                title: Text(
                                  b.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Text(
                                  Formatters.currency(b.netBalance),
                                  style: TextStyle(
                                    color: b.netBalance >= 0
                                        ? Theme.of(context).colorScheme.tertiary
                                        : Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  membersAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (members) => Text(
                      '${AppStrings.groupMembers}: ${members.map((m) => m.displayName).join(', ')}',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _GroupExpensesSection(state: expensesState),
                  PaginatedListFooter(
                    state: expensesState,
                    onRetryLoadMore: () => ref
                        .read(expenseGroupExpensesProvider((groupId, range))
                            .notifier)
                        .loadMore(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GroupExpensesSection extends StatelessWidget {
  const _GroupExpensesSection({required this.state});

  final PaginatedListState<Expense> state;

  @override
  Widget build(BuildContext context) {
    if (state.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.hasError) {
      return const SizedBox.shrink();
    }
    if (state.items.isEmpty) {
      return const Text(AppStrings.emptyExpenses);
    }
    return Column(
      children: state.items
          .map(
            (e) => Card(
              child: ListTile(
                title: Text(
                  e.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  [
                    Formatters.date(e.expenseDate),
                    if (e.paidByMemberName != null)
                      '${AppStrings.paidByMember}: ${e.paidByMemberName}',
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(Formatters.currency(e.amount)),
              ),
            ),
          )
          .toList(),
    );
  }
}
