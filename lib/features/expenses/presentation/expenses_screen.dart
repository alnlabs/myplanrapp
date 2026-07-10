import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../../shared/models/expense.dart';
import '../../../shared/models/family_member.dart';
import '../../../shared/models/recurring_money_rule.dart';
import '../../../shared/providers/list_display_mode_provider.dart';
import '../../../shared/providers/paginated_list_state.dart';
import '../../../shared/providers/record_permissions.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/utils/offline_guard.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/feature_screen_app_bar.dart';
import '../../../shared/widgets/list_display_mode_toggle.dart';
import '../../../shared/widgets/compact_grid_card.dart';
import '../../../shared/widgets/list_grid_layout.dart';
import '../../../shared/widgets/paginated_list_footer.dart';
import '../../auth/data/auth_repository.dart';
import '../../household/data/family_repository.dart';
import '../data/expense_date_filter_provider.dart';
import '../data/expense_groups_repository.dart';
import '../data/expense_repository.dart';
import '../data/expenses_list_provider.dart';
import '../data/money_list_filter_provider.dart';
import '../data/recurring_money_rule_repository.dart';
import '../utils/expense_csv_export.dart';
import '../utils/expense_period_label.dart';
import '../utils/money_report_export.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';
import 'expense_period_filter_bar.dart';
import 'expense_summary_screen.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAutoLog());
  }

  Future<void> _runAutoLog() async {
    final count = await processAutoLogRecurringExpenses(ref);
    if (count > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.recurringLogged)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(expensesListProvider);
    final moneySummaryAsync = ref.watch(moneySummaryProvider);
    final memberIncomeAsync = ref.watch(memberIncomeSummaryProvider);
    final filters = ref.watch(moneyListFilterProvider);
    final viewMode =
        ref.watch(listDisplayModeProvider(ListDisplayModeKeys.expenses));
    final dueIncomeAsync = ref.watch(dueRecurringIncomeProvider);
    final dueExpenseAsync = ref.watch(dueRecurringExpenseProvider);

    return Scaffold(
      appBar: FeatureScreenAppBar.forShellRoute(
        context,
        title: AppStrings.expensesTitle,
        subtitle: AppStrings.expensesSubtitle,
        actions: [
          IconButton(
            onPressed: () => context.push('/expenses/recurring'),
            icon: const Icon(Icons.event_repeat_outlined),
            tooltip: AppStrings.recurringExpenses,
          ),
          IconButton(
            onPressed: () => context.push('/expenses/groups'),
            icon: const Icon(Icons.groups_outlined),
            tooltip: AppStrings.expenseGroupsTitle,
          ),
          IconButton(
            onPressed: () => _exportReport(context, ref),
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: AppStrings.exportReport,
          ),
          const ListDisplayModeToggle(screenKey: ListDisplayModeKeys.expenses),
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
          await refreshExpensesData(ref);
          await _runAutoLog();
        },
        child: _buildBody(
          context,
          ref,
          listState,
          moneySummaryAsync,
          memberIncomeAsync,
          dueIncomeAsync,
          dueExpenseAsync,
          filters,
          viewMode,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMenu(context, ref),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addExpense),
      ),
    );
  }

  Future<void> _exportReport(BuildContext context, WidgetRef ref) async {
    try {
      ref.ensureOnline();
      final profile = await ref.read(userProfileProvider.future);
      final householdId = profile?.activeHouseholdId;
      if (householdId == null) return;
      final filters = ref.read(moneyListFilterProvider);
      final range = ref.read(expenseDateRangeProvider);
      final dateFilter = ref.read(expenseDateFilterProvider);
      final all = await ref.read(expenseRepositoryProvider).fetchForExport(
            householdId,
            range.start,
            range.end,
            entryType: filters.entryType,
            familyMemberId: filters.familyMemberId,
          );
      if (all.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.emptyExport)),
          );
        }
        return;
      }
      final truncated = all.length >= 5000;
      final csv = ExpenseCsvExport.build(
        entries: all,
        periodLabel: expensePeriodExportLabel(dateFilter),
        truncated: truncated,
      );
      if (context.mounted) {
        await showMoneyReportExportSheet(context, csv: csv);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorFormatter.format(e))),
        );
      }
    }
  }

  Future<void> _showAddMenu(BuildContext context, WidgetRef ref) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text(AppStrings.addExpense),
              onTap: () => Navigator.pop(context, 'expense'),
            ),
            ListTile(
              leading: const Icon(Icons.savings_outlined),
              title: const Text(AppStrings.addIncome),
              onTap: () => Navigator.pop(context, 'income'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => choice == 'income'
            ? const AddIncomeScreen()
            : const AddExpenseScreen(),
      ),
    );
    if (updated == true) await refreshExpensesData(ref);
  }

  Future<void> _logDueRecurringExpense(
    BuildContext context,
    WidgetRef ref,
    RecurringMoneyRule rule,
  ) async {
    try {
      ref.ensureOnline();
      if (rule.autoLog) {
        await ref
            .read(recurringMoneyRuleRepositoryProvider)
            .logRecurringExpense(rule.id);
        await refreshExpensesData(ref);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.recurringLogged)),
          );
        }
        return;
      }
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
      if (updated == true) await refreshExpensesData(ref);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorFormatter.format(e))),
        );
      }
    }
  }

  Future<void> _skipDueRecurringExpense(
    WidgetRef ref,
    RecurringMoneyRule rule,
  ) async {
    try {
      ref.ensureOnline();
      await ref.read(recurringMoneyRuleRepositoryProvider).advanceRule(rule.id);
      await refreshExpensesData(ref);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorFormatter.format(e))),
        );
      }
    }
  }

  Future<void> _snoozeDueRecurringExpense(
    WidgetRef ref,
    RecurringMoneyRule rule,
  ) async {
    try {
      ref.ensureOnline();
      final until = DateTime.now().add(const Duration(days: 7));
      await ref.read(recurringMoneyRuleRepositoryProvider).snoozeRule(rule.id, until);
      await refreshExpensesData(ref);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorFormatter.format(e))),
        );
      }
    }
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    PaginatedListState<Expense> listState,
    AsyncValue<MoneySummary> moneySummaryAsync,
    AsyncValue<List<MemberIncomeSummary>> memberIncomeAsync,
    AsyncValue<List<RecurringMoneyRule>> dueIncomeAsync,
    AsyncValue<List<RecurringMoneyRule>> dueExpenseAsync,
    MoneyListFilterState filters,
    ListDisplayMode viewMode,
  ) {
    if (listState.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (listState.hasError) {
      return ErrorView(
        error: listState.error!,
        message: ApiErrorFormatter.format(listState.error!),
        onRetry: () => ref.read(expensesListProvider.notifier).refresh(),
      );
    }

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ExpensePeriodFilterBar(),
        const SizedBox(height: 12),
        _MoneyFilterBar(
          filters: filters,
          onTypeChanged: (filter) {
            ref.read(moneyListFilterProvider.notifier).setTypeFilter(filter);
            ref.read(expensesListProvider.notifier).refresh();
          },
          onMemberChanged: (memberId) {
            ref.read(moneyListFilterProvider.notifier).setFamilyMemberId(memberId);
            ref.read(expensesListProvider.notifier).refresh();
          },
          onGroupChanged: (groupId) {
            ref.read(moneyListFilterProvider.notifier).setGroupId(groupId);
            ref.read(expensesListProvider.notifier).refresh();
          },
        ),
        const SizedBox(height: 12),
        dueIncomeAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (rules) {
            if (rules.isEmpty) return const SizedBox.shrink();
            final rule = rules.first;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.event_repeat),
                title: const Text(AppStrings.recurringIncomeDue),
                subtitle: Text(
                  '${rule.displayLabel} · ${Formatters.currency(rule.amount)}',
                ),
                trailing: TextButton(
                  onPressed: () async {
                    final updated = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => AddIncomeScreen(
                          initialFamilyMemberId: rule.familyMemberId,
                          initialIncomeSource: rule.incomeSource,
                          initialAmount: rule.amount,
                          initialCategoryId: rule.categoryId,
                          recurringRuleId: rule.id,
                        ),
                      ),
                    );
                    if (updated == true) await refreshExpensesData(ref);
                  },
                  child: const Text(AppStrings.logRecurringIncome),
                ),
              ),
            );
          },
        ),
        dueExpenseAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (rules) {
            if (rules.isEmpty) return const SizedBox.shrink();
            return Column(
              children: rules.map((rule) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.event_repeat_outlined),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    AppStrings.recurringExpenseDue,
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '${rule.displayLabel} · ${Formatters.currency(rule.amount)}',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton(
                              onPressed: () => _logDueRecurringExpense(
                                context,
                                ref,
                                rule,
                              ),
                              child: const Text(AppStrings.logRecurringExpense),
                            ),
                            TextButton(
                              onPressed: () => _skipDueRecurringExpense(ref, rule),
                              child: const Text(AppStrings.skipRecurring),
                            ),
                            TextButton(
                              onPressed: () => _snoozeDueRecurringExpense(ref, rule),
                              child: const Text(AppStrings.snoozeRecurring),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        moneySummaryAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (summary) => _MoneySummaryCard(
            summary: summary,
            memberIncome: memberIncomeAsync.valueOrNull ?? const [],
            periodLabel: expensePeriodLabel(ref.watch(expenseDateFilterProvider)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );

    if (listState.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        children: [
          header,
          EmptyState(
            icon: filters.typeFilter == MoneyListFilter.income
                ? Icons.savings_outlined
                : Icons.payments_outlined,
            title: filters.typeFilter == MoneyListFilter.income
                ? AppStrings.emptyIncome
                : AppStrings.emptyExpenses,
            subtitle: AppStrings.emptyExpensesHint,
            actionLabel: filters.typeFilter == MoneyListFilter.income
                ? AppStrings.addIncome
                : AppStrings.addExpense,
            onAction: () => _showAddMenu(context, ref),
          ),
        ],
      );
    }

    return PaginatedScrollListener(
      onLoadMore: () => ref.read(expensesListProvider.notifier).loadMore(),
      child: viewMode == ListDisplayMode.list
          ? ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                header,
                _ExpenseList(
                  expenses: listState.items,
                  onExpenseChanged: () => refreshExpensesData(ref),
                ),
                PaginatedListFooter(
                  state: listState,
                  onRetryLoadMore: () =>
                      ref.read(expensesListProvider.notifier).loadMore(),
                ),
              ],
            )
          : _ExpenseGrid(
              header: header,
              expenses: listState.items,
              footer: PaginatedListFooter(
                state: listState,
                onRetryLoadMore: () =>
                    ref.read(expensesListProvider.notifier).loadMore(),
              ),
              onExpenseChanged: () => refreshExpensesData(ref),
            ),
    );
  }
}

class _MoneyFilterBar extends ConsumerWidget {
  const _MoneyFilterBar({
    required this.filters,
    required this.onTypeChanged,
    required this.onMemberChanged,
    required this.onGroupChanged,
  });

  final MoneyListFilterState filters;
  final ValueChanged<MoneyListFilter> onTypeChanged;
  final ValueChanged<String?> onMemberChanged;
  final ValueChanged<String?> onGroupChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(familyRosterProvider);
    final groupsAsync = ref.watch(expenseGroupsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text(AppStrings.filterAllMoney),
              selected: filters.typeFilter == MoneyListFilter.all,
              onSelected: (_) => onTypeChanged(MoneyListFilter.all),
            ),
            ChoiceChip(
              label: const Text(AppStrings.filterExpensesOnly),
              selected: filters.typeFilter == MoneyListFilter.expenses,
              onSelected: (_) => onTypeChanged(MoneyListFilter.expenses),
            ),
            ChoiceChip(
              label: const Text(AppStrings.filterIncomeOnly),
              selected: filters.typeFilter == MoneyListFilter.income,
              onSelected: (_) => onTypeChanged(MoneyListFilter.income),
            ),
          ],
        ),
        if (filters.typeFilter == MoneyListFilter.income)
          rosterAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (members) {
              if (members.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: DropdownButtonFormField<String?>(
                  value: filters.familyMemberId,
                  decoration: const InputDecoration(
                    labelText: AppStrings.filterByMember,
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text(AppStrings.filterAllMoney),
                    ),
                    ...members.map(
                      (FamilyMember m) => DropdownMenuItem<String?>(
                        value: m.id,
                        child: Text(m.listLabel),
                      ),
                    ),
                  ],
                  onChanged: onMemberChanged,
                ),
              );
            },
          ),
        groupsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (groups) {
            if (groups.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: DropdownButtonFormField<String?>(
                value: filters.groupId,
                decoration: const InputDecoration(
                  labelText: AppStrings.expenseGroup,
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text(AppStrings.filterAllMoney),
                  ),
                  ...groups.map(
                    (g) => DropdownMenuItem<String?>(
                      value: g.id,
                      child: Text(g.name),
                    ),
                  ),
                ],
                onChanged: onGroupChanged,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MoneySummaryCard extends StatefulWidget {
  const _MoneySummaryCard({
    required this.summary,
    required this.memberIncome,
    required this.periodLabel,
  });

  final MoneySummary summary;
  final List<MemberIncomeSummary> memberIncome;
  final String periodLabel;

  @override
  State<_MoneySummaryCard> createState() => _MoneySummaryCardState();
}

class _MoneySummaryCardState extends State<_MoneySummaryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final netColor = widget.summary.netAmount >= 0
        ? theme.colorScheme.tertiary
        : theme.colorScheme.error;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.periodLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimary.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppStrings.moneyNet,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    Formatters.currency(widget.summary.netAmount),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: netColor.withOpacity(0.95),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MoneyStat(
                  label: AppStrings.moneySpent,
                  amount: widget.summary.totalSpent,
                ),
              ),
              Expanded(
                child: _MoneyStat(
                  label: AppStrings.moneyEarned,
                  amount: widget.summary.totalEarned,
                ),
              ),
            ],
          ),
          if (widget.memberIncome.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.earnedByMember,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withOpacity(0.9),
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onPrimary,
                  ),
                ],
              ),
            ),
            if (_expanded)
              ...widget.memberIncome.map(
                (row) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.memberName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimary.withOpacity(0.85),
                          ),
                        ),
                      ),
                      Text(
                        Formatters.currency(row.earnedTotal),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _MoneyStat extends StatelessWidget {
  const _MoneyStat({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onPrimary.withOpacity(0.75),
          ),
        ),
        Text(
          Formatters.currency(amount),
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ExpenseGrid extends ConsumerWidget {
  const _ExpenseGrid({
    required this.header,
    required this.expenses,
    required this.footer,
    required this.onExpenseChanged,
  });

  final Widget header;
  final List<Expense> expenses;
  final Widget footer;
  final VoidCallback onExpenseChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(child: header),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          sliver: SliverGrid(
            gridDelegate: ListGridLayout.gridDelegate,
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final expense = expenses[index];
                return _ExpenseGridCard(
                  expense: expense,
                  onTap: () => _openEntry(context, ref, expense, onExpenseChanged),
                );
              },
              childCount: expenses.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: footer,
          ),
        ),
      ],
    );
  }
}

Future<void> _openEntry(
  BuildContext context,
  WidgetRef ref,
  Expense expense,
  VoidCallback onChanged,
) async {
  final currentUserId = ref.read(currentUserIdProvider);
  final isOwner = ref.read(isHouseholdOwnerProvider);
  final canEdit = canManageRecord(
    createdBy: expense.createdBy,
    currentUserId: currentUserId,
    isOwner: isOwner,
  );
  if (!canEdit) return;

  final updated = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => expense.isIncome
          ? AddIncomeScreen(income: expense)
          : AddExpenseScreen(expense: expense),
    ),
  );
  if (updated == true) onChanged();
}

class _ExpenseGridCard extends StatelessWidget {
  const _ExpenseGridCard({required this.expense, required this.onTap});

  final Expense expense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = expense.isIncome;
    return CompactGridCard(
      onTap: onTap,
      leading: CompactGridIcon(
        icon: isIncome ? Icons.savings_outlined : Icons.receipt_long_outlined,
        color: isIncome
            ? theme.colorScheme.tertiary
            : theme.colorScheme.onSurfaceVariant,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
      title: expense.title,
      subtitle: [
        '${isIncome ? '+' : ''}${Formatters.currency(expense.amount)}',
        if (expense.categoryName != null) expense.categoryName!,
        if (isIncome && expense.familyMemberName != null)
          expense.familyMemberName!,
      ].join(' · '),
    );
  }
}

class _ExpenseList extends ConsumerWidget {
  const _ExpenseList({
    required this.expenses,
    required this.onExpenseChanged,
  });

  final List<Expense> expenses;
  final VoidCallback onExpenseChanged;

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
        final dayTotal = entry.value.fold<double>(
          0.0,
          (double sum, Expense expense) =>
              sum + (expense.isIncome ? expense.amount : -expense.amount),
        );
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
                    Formatters.currency(dayTotal.abs()),
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
              final isIncome = expense.isIncome;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      isIncome
                          ? Icons.savings_outlined
                          : Icons.receipt_long_outlined,
                      color: isIncome
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  title: Text(expense.title),
                  subtitle: Text(
                    [
                      if (expense.categoryName != null) expense.categoryName!,
                      if (expense.groupName != null) expense.groupName!,
                      if (isIncome && expense.familyMemberName != null)
                        expense.familyMemberName!,
                      if (isIncome && expense.displaySource != expense.title)
                        expense.displaySource,
                      if (creatorName != null) AppStrings.addedBy(creatorName),
                    ].join(' · '),
                  ),
                  trailing: Text(
                    '${isIncome ? '+' : ''}${Formatters.currency(expense.amount)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isIncome ? theme.colorScheme.tertiary : null,
                    ),
                  ),
                  onTap: canEdit
                      ? () => _openEntry(
                            context,
                            ref,
                            expense,
                            onExpenseChanged,
                          )
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
                          onExpenseChanged();
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
