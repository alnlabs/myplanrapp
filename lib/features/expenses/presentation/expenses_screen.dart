import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../../shared/models/expense.dart';
import '../../../shared/models/expense_group.dart';
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
import '../../../shared/widgets/list_display_mode_toggle.dart';
import '../../../shared/widgets/compact_grid_card.dart';
import '../../../shared/widgets/list_grid_layout.dart';
import '../../../shared/widgets/paginated_list_footer.dart';
import '../../../shared/widgets/value_text.dart';
import '../../auth/data/auth_repository.dart';
import '../../household/data/family_repository.dart';
import '../data/expense_date_filter.dart';
import '../data/expense_date_filter_provider.dart';
import '../data/expense_groups_repository.dart';
import '../data/expense_repository.dart';
import '../data/expense_view_provider.dart';
import '../data/expenses_list_provider.dart';
import '../data/money_list_filter_provider.dart';
import '../data/recurring_money_rule_repository.dart';
import '../utils/expense_csv_export.dart';
import '../utils/expense_period_label.dart';
import '../utils/money_report_export.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';
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
        const SnackBar(content: Text(AppStrings.recurringLogged)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(expenseViewProvider);
    final listState = ref.watch(expensesListProvider);
    final moneySummaryAsync = ref.watch(moneySummaryProvider);
    final memberIncomeAsync = ref.watch(memberIncomeSummaryProvider);
    final filters = ref.watch(moneyListFilterProvider);
    final viewMode =
        ref.watch(listDisplayModeProvider(ListDisplayModeKeys.expenses));
    final dueIncomeAsync = ref.watch(dueRecurringIncomeProvider);
    final dueExpenseAsync = ref.watch(dueRecurringExpenseProvider);
    final isGroupsHub = view.kind == ExpenseViewKind.groups;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        toolbarHeight: 64,
        title: const _ViewMenuButton(),
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
          const ListDisplayModeToggle(screenKey: ListDisplayModeKeys.expenses),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: AppStrings.moreActions,
            onSelected: (value) {
              if (value == 'recurring') {
                context.push('/expenses/recurring');
              } else if (value == 'export') {
                _exportReport(context, ref);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'recurring',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.event_repeat_outlined),
                  title: Text(AppStrings.recurringExpenses),
                ),
              ),
              PopupMenuItem<String>(
                value: 'export',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.ios_share_outlined),
                  title: Text(AppStrings.exportReport),
                ),
              ),
            ],
          ),
        ],
      ),
      body: isGroupsHub
          ? const _GroupsHubView()
          : RefreshIndicator(
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
      floatingActionButton: isGroupsHub
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/expenses/groups/add'),
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.newGroup),
            )
          : FloatingActionButton.extended(
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
      useRootNavigator: true,
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
    final view = ref.read(expenseViewProvider);
    final scope = view.scope ?? MoneyScope.household;
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => choice == 'income'
            ? AddIncomeScreen(initialScope: scope)
            : AddExpenseScreen(
                initialScope: scope,
                initialGroupId: view.groupFilterId,
              ),
      ),
    );
    if (updated == true) await refreshExpensesData(ref);
  }

  int _activeFilterCount(MoneyListFilterState filters) {
    var count = 0;
    if (filters.typeFilter != MoneyListFilter.all) count++;
    if (filters.familyMemberId != null) count++;
    return count;
  }

  Future<void> _showPeriodSheet(BuildContext context, WidgetRef ref) async {
    final current = ref.read(expenseDateFilterProvider).preset;
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (sheetContext) {
        Widget tile(ExpenseDatePreset preset, String label, IconData icon) {
          return ListTile(
            leading: Icon(icon),
            title: Text(label),
            trailing: current == preset
                ? Icon(
                    Icons.check,
                    color: Theme.of(sheetContext).colorScheme.primary,
                  )
                : null,
            onTap: () async {
              Navigator.pop(sheetContext);
              if (preset == ExpenseDatePreset.custom) {
                await _pickCustomRange(context, ref);
              } else {
                ref.read(expenseDateFilterProvider.notifier).setPreset(preset);
                await ref.read(expensesListProvider.notifier).refresh();
              }
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  AppStrings.moneyPeriodLabel,
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              tile(
                ExpenseDatePreset.today,
                AppStrings.periodToday,
                Icons.today_outlined,
              ),
              tile(
                ExpenseDatePreset.week,
                AppStrings.periodThisWeek,
                Icons.date_range_outlined,
              ),
              tile(
                ExpenseDatePreset.month,
                AppStrings.periodThisMonth,
                Icons.calendar_month_outlined,
              ),
              tile(
                ExpenseDatePreset.custom,
                AppStrings.periodCustomRange,
                Icons.edit_calendar_outlined,
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickCustomRange(BuildContext context, WidgetRef ref) async {
    final filter = ref.read(expenseDateFilterProvider);
    final now = DateTime.now();
    final initialStart = filter.customStart ?? DateTime(now.year, now.month, 1);
    final initialEnd = filter.customEnd ?? now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
    );
    if (picked == null) return;

    final error = filter.customRangeError(picked.start, picked.end);
    if (error != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }

    ref
        .read(expenseDateFilterProvider.notifier)
        .setCustomRange(picked.start, picked.end);
    await ref.read(expensesListProvider.notifier).refresh();
  }

  Future<void> _showFilterSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _ExpenseFilterSheet(),
    );
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

    final periodLabel =
        expensePeriodLabel(ref.watch(expenseDateFilterProvider));
    final activeFilterCount = _activeFilterCount(filters);

    final currentUserId = ref.watch(currentUserIdProvider);
    String? currentMemberId;
    if (currentUserId != null) {
      final roster = ref.watch(familyRosterProvider).valueOrNull;
      if (roster != null) {
        for (final member in roster) {
          if (member.userId == currentUserId) {
            currentMemberId = member.id;
            break;
          }
        }
      }
    }

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ActionChip(
                avatar: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Row(
                  children: [
                    Expanded(
                      child: Text(
                        periodLabel,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 20),
                  ],
                ),
                onPressed: () => _showPeriodSheet(context, ref),
              ),
            ),
            const SizedBox(width: 8),
            Badge.count(
              count: activeFilterCount,
              isLabelVisible: activeFilterCount > 0,
              child: IconButton.filledTonal(
                onPressed: () => _showFilterSheet(context, ref),
                icon: const Icon(Icons.tune),
                tooltip: AppStrings.filterList,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        moneySummaryAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (summary) => _MoneySummaryCard(
            summary: summary,
            memberIncome: memberIncomeAsync.valueOrNull ?? const [],
            periodLabel: expensePeriodLabel(ref.watch(expenseDateFilterProvider)),
            currentMemberId: currentMemberId,
          ),
        ),
        const SizedBox(height: 16),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.transactionsTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            if (activeFilterCount > 0)
              TextButton.icon(
                onPressed: () {
                  ref
                      .read(moneyListFilterProvider.notifier)
                      .setTypeFilter(MoneyListFilter.all);
                  ref.read(expensesListProvider.notifier).refresh();
                },
                icon: const Icon(Icons.close, size: 16),
                label: const Text(AppStrings.clearFilters),
              ),
          ],
        ),
        const SizedBox(height: 8),
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

/// Compact app-bar dropdown that drives the top-level Expenses view
/// (All / Personal / Household / Groups). Replaces the full-width tab bar so
/// the controls no longer consume a body row, and stays reachable from the
/// Groups hub too.
class _ViewMenuButton extends ConsumerWidget {
  const _ViewMenuButton();

  static String _label(ExpenseViewKind kind) {
    return switch (kind) {
      ExpenseViewKind.all => AppStrings.viewMoneyAll,
      ExpenseViewKind.personal => AppStrings.viewMoneyPersonal,
      ExpenseViewKind.household => AppStrings.viewMoneyHousehold,
      ExpenseViewKind.groups => AppStrings.viewMoneyGroups,
      ExpenseViewKind.group => AppStrings.viewMoneyGroups,
    };
  }

  static String _hint(ExpenseViewKind kind) {
    return switch (kind) {
      ExpenseViewKind.all => AppStrings.viewMoneyAllHint,
      ExpenseViewKind.personal => AppStrings.viewMoneyPersonalHint,
      ExpenseViewKind.household => AppStrings.viewMoneyHouseholdHint,
      ExpenseViewKind.groups => AppStrings.viewMoneyGroupsHint,
      ExpenseViewKind.group => AppStrings.viewMoneyGroupsHint,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(expenseViewProvider);
    final selected = view.isGroupsTab ? ExpenseViewKind.groups : view.kind;
    final theme = Theme.of(context);

    void select(ExpenseViewKind kind) {
      final next = switch (kind) {
        ExpenseViewKind.all => const ExpenseView.all(),
        ExpenseViewKind.personal => const ExpenseView.personal(),
        ExpenseViewKind.household => const ExpenseView.household(),
        ExpenseViewKind.groups => const ExpenseView.groups(),
        ExpenseViewKind.group => const ExpenseView.groups(),
      };
      ref.read(expenseViewProvider.notifier).setView(next);
      ref.read(expensesListProvider.notifier).refresh();
    }

    return PopupMenuButton<ExpenseViewKind>(
      tooltip: AppStrings.expensesTitle,
      onSelected: select,
      itemBuilder: (context) => [
        for (final kind in const [
          ExpenseViewKind.all,
          ExpenseViewKind.personal,
          ExpenseViewKind.household,
          ExpenseViewKind.groups,
        ])
          CheckedPopupMenuItem<ExpenseViewKind>(
            value: kind,
            checked: kind == selected,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(_label(kind)),
              subtitle: Text(_hint(kind)),
            ),
          ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _label(selected),
                  overflow: TextOverflow.ellipsis,
                  style: (theme.appBarTheme.titleTextStyle ??
                          theme.textTheme.titleLarge)
                      ?.copyWith(height: 1.1),
                ),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
          Text(
            _hint(selected),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// The "Groups" tab: a hub of group cards (name, members, your balance) with a
/// shortcut to full group management. Tapping a card opens the group detail
/// (expenses + balances + settle).
class _GroupsHubView extends ConsumerWidget {
  const _GroupsHubView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(expenseGroupsProvider);
    final theme = Theme.of(context);

    return groupsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorView(
        error: error,
        message: ApiErrorFormatter.format(error),
        onRetry: () => ref.invalidate(expenseGroupsProvider),
      ),
      data: (groups) {
        if (groups.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              EmptyState(
                icon: Icons.groups_outlined,
                title: AppStrings.emptyExpenseGroups,
                subtitle: AppStrings.emptyExpenseGroupsHint,
                actionLabel: AppStrings.newGroup,
                onAction: () => context.push('/expenses/groups/add'),
              ),
            ],
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(expenseGroupsProvider),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: groups.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    AppStrings.groupsHubHint,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }
              final group = groups[index - 1];
              return _GroupCard(group: group);
            },
          ),
        );
      },
    );
  }
}

class _GroupCard extends ConsumerWidget {
  const _GroupCard({required this.group});

  final ExpenseGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final balanceAsync = group.isShared
        ? ref.watch(expenseGroupMyBalanceProvider(group.id))
        : const AsyncValue<double?>.data(null);

    Widget balanceLine() {
      final balance = balanceAsync.valueOrNull;
      if (balance == null) {
        return Text(
          group.isShared
              ? AppStrings.groupTypeShared
              : AppStrings.groupTypeOrganizational,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
      }
      final settled = balance.abs() < 0.01;
      final owed = balance > 0;
      final color = settled
          ? theme.colorScheme.onSurfaceVariant
          : (owed ? theme.colorScheme.tertiary : theme.colorScheme.error);
      final label = settled
          ? AppStrings.balanceSettledUp
          : (owed ? AppStrings.balanceYouAreOwed : AppStrings.balanceYouOwe);
      return Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
          if (!settled) ...[
            const SizedBox(width: 4),
            ValueText(
              Formatters.currency(balance.abs()),
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/expenses/groups/${group.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  group.isShared ? Icons.people_outline : Icons.folder_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.membersCount(group.memberCount ?? 0),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    balanceLine(),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseFilterSheet extends ConsumerWidget {
  const _ExpenseFilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filters = ref.watch(moneyListFilterProvider);
    final rosterAsync = ref.watch(familyRosterProvider);

    void refresh() => ref.read(expensesListProvider.notifier).refresh();

    void setType(MoneyListFilter filter) {
      ref.read(moneyListFilterProvider.notifier).setTypeFilter(filter);
      refresh();
    }

    void setMember(String? id) {
      ref.read(moneyListFilterProvider.notifier).setFamilyMemberId(id);
      refresh();
    }

    final hasActive = filters.typeFilter != MoneyListFilter.all ||
        filters.familyMemberId != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.filterList,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: hasActive
                      ? () {
                          ref
                              .read(moneyListFilterProvider.notifier)
                              .setTypeFilter(MoneyListFilter.all);
                          refresh();
                        }
                      : null,
                  child: const Text(AppStrings.clearFilters),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<MoneyListFilter>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: const [
                  ButtonSegment(
                    value: MoneyListFilter.all,
                    label: Text(AppStrings.filterAllMoney),
                  ),
                  ButtonSegment(
                    value: MoneyListFilter.expenses,
                    label: Text(AppStrings.filterExpensesOnly),
                  ),
                  ButtonSegment(
                    value: MoneyListFilter.income,
                    label: Text(AppStrings.filterIncomeOnly),
                  ),
                ],
                selected: {filters.typeFilter},
                onSelectionChanged: (selection) => setType(selection.first),
              ),
            ),
            if (filters.typeFilter == MoneyListFilter.income)
              rosterAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (members) {
                  if (members.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: DropdownButtonFormField<String?>(
                      value: filters.familyMemberId,
                      decoration: const InputDecoration(
                        labelText: AppStrings.filterByMember,
                        isDense: true,
                        border: OutlineInputBorder(),
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
                      onChanged: setMember,
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(AppStrings.doneLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoneySummaryCard extends StatefulWidget {
  const _MoneySummaryCard({
    required this.summary,
    required this.memberIncome,
    required this.periodLabel,
    this.currentMemberId,
  });

  final MoneySummary summary;
  final List<MemberIncomeSummary> memberIncome;
  final String periodLabel;
  final String? currentMemberId;

  @override
  State<_MoneySummaryCard> createState() => _MoneySummaryCardState();
}

class _MoneySummaryCardState extends State<_MoneySummaryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // High-contrast tints that stay readable on the teal gradient card.
    const positiveColor = Color(0xFFB9F6CA);
    const negativeColor = Color(0xFFFFB4AB);
    final netColor =
        widget.summary.netAmount >= 0 ? positiveColor : negativeColor;
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppStrings.moneyNet,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary.withOpacity(0.9),
                      ),
                    ),
                    ValueText(
                      Formatters.currency(widget.summary.netAmount),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: netColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
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
                  amountColor: negativeColor,
                ),
              ),
              Expanded(
                child: _MoneyStat(
                  label: AppStrings.moneyEarned,
                  amount: widget.summary.totalEarned,
                  amountColor: positiveColor,
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
                          row.familyMemberId == widget.currentMemberId
                              ? AppStrings.me
                              : row.memberName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimary.withOpacity(0.95),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: ValueText(
                          Formatters.currency(row.earnedTotal),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
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
  const _MoneyStat({
    required this.label,
    required this.amount,
    this.amountColor,
  });

  final String label;
  final double amount;
  final Color? amountColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onPrimary.withOpacity(0.9),
          ),
        ),
        ValueText(
          Formatters.currency(amount),
          alignment: Alignment.centerLeft,
          style: theme.textTheme.titleMedium?.copyWith(
            color: amountColor ?? theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w700,
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

    String? currentMemberId;
    if (currentUserId != null) {
      final roster = ref.watch(familyRosterProvider).valueOrNull;
      if (roster != null) {
        for (final member in roster) {
          if (member.userId == currentUserId) {
            currentMemberId = member.id;
            break;
          }
        }
      }
    }

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
                  const SizedBox(width: 8),
                  Flexible(
                    child: ValueText(
                      Formatters.currency(dayTotal.abs()),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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
              final isIncome = expense.isIncome;
              // Show "Me" for the logged-in user, names for everyone else.
              final creatorName = expense.createdBy != null
                  ? (expense.createdBy == currentUserId
                      ? AppStrings.me
                      : memberNames[expense.createdBy])
                  : null;
              final earnerName = expense.familyMemberName == null
                  ? null
                  : (currentMemberId != null &&
                          expense.familyMemberId == currentMemberId
                      ? AppStrings.me
                      : expense.familyMemberName);
              final metaParts = <String>[];
              void addMeta(String? value) {
                if (value == null || value.isEmpty) return;
                if (value == expense.title) return;
                if (metaParts.contains(value)) return;
                metaParts.add(value);
              }

              addMeta(expense.categoryName);
              addMeta(expense.groupName);
              if (isIncome) {
                addMeta(earnerName);
                if (expense.displaySource != expense.title) {
                  addMeta(expense.displaySource);
                }
              }
              // Skip "Added by" when the logger is the same person already
              // shown as the income earner (avoids "X · Added by X").
              final hideAddedBy = isIncome && creatorName == earnerName;
              if (creatorName != null && !hideAddedBy) {
                addMeta(AppStrings.addedBy(creatorName));
              }
              final meta = metaParts.join(' · ');
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
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
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
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
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expense.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              ValueText(
                                '${isIncome ? '+' : ''}'
                                '${Formatters.currency(expense.amount)}',
                                alignment: Alignment.centerLeft,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isIncome
                                      ? theme.colorScheme.tertiary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              if (meta.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  meta,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      }).toList(),
    );
  }
}
