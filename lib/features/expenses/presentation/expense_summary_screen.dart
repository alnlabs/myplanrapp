import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../../../shared/widgets/value_text.dart';
import '../data/expense_date_filter.dart';
import '../data/expense_date_filter_provider.dart';
import '../data/expense_repository.dart';
import '../data/expenses_list_provider.dart';
import '../utils/expense_period_label.dart';

class ExpenseSummaryScreen extends ConsumerWidget {
  const ExpenseSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseSummaryAsync = ref.watch(expenseSummaryProvider);
    final moneySummaryAsync = ref.watch(moneySummaryProvider);
    final memberIncomeAsync = ref.watch(memberIncomeSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.summaryTitle),
        actions: const [
          _ViewTypeMenu(),
        ],
      ),
      body: AsyncScreenBody(
        value: moneySummaryAsync,
        onRetry: () {
          ref.invalidate(moneySummaryProvider);
          ref.invalidate(expenseSummaryProvider);
          ref.invalidate(memberIncomeSummaryProvider);
          ref.invalidate(expenseComparisonProvider);
        },
        isEmpty: (_) => false,
        builder: (moneySummary) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expensePeriodLabel(ref.watch(expenseDateFilterProvider)),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _SummaryRow(
                        label: AppStrings.moneySpent,
                        amount: moneySummary.totalSpent,
                      ),
                      _SummaryRow(
                        label: AppStrings.moneyEarned,
                        amount: moneySummary.totalEarned,
                      ),
                      const Divider(height: 24),
                      _SummaryRow(
                        label: AppStrings.moneyNet,
                        amount: moneySummary.netAmount,
                        emphasized: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const _HistoryChartCard(),
              const SizedBox(height: 12),
              memberIncomeAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (rows) {
                  if (rows.isEmpty) return const SizedBox.shrink();
                  return Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            AppStrings.earnedByMember,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        ...rows.map(
                          (row) => ListTile(
                            title: Text(
                              row.memberName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              Formatters.currency(row.earnedTotal),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              expenseSummaryAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
                data: (rows) {
                  if (rows.isEmpty) return const SizedBox.shrink();
                  return Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            AppStrings.filterExpensesOnly,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        ...rows.map(
                          (row) => ListTile(
                            title: Text(
                              row.categoryName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              Formatters.currency(row.totalAmount),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ViewTypeMenu extends ConsumerWidget {
  const _ViewTypeMenu();

  Future<void> _select(
    BuildContext context,
    WidgetRef ref,
    ExpenseDatePreset preset,
  ) async {
    if (preset == ExpenseDatePreset.custom) {
      final filter = ref.read(expenseDateFilterProvider);
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: now.add(const Duration(days: 365)),
        initialDateRange: DateTimeRange(
          start: filter.customStart ?? DateTime(now.year, now.month, 1),
          end: filter.customEnd ?? now,
        ),
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
    } else {
      ref.read(expenseDateFilterProvider.notifier).setPreset(preset);
    }
    await ref.read(expensesListProvider.notifier).refresh();
  }

  String _label(ExpenseDatePreset preset) => switch (preset) {
        ExpenseDatePreset.today => AppStrings.viewDay,
        ExpenseDatePreset.week => AppStrings.viewWeek,
        ExpenseDatePreset.month => AppStrings.viewMonth,
        ExpenseDatePreset.custom => AppStrings.viewCustom,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preset = ref.watch(expenseDateFilterProvider).preset;
    return PopupMenuButton<ExpenseDatePreset>(
      tooltip: AppStrings.viewType,
      onSelected: (value) => _select(context, ref, value),
      itemBuilder: (context) => [
        for (final option in ExpenseDatePreset.values)
          CheckedPopupMenuItem(
            value: option,
            checked: option == preset,
            child: Text(_label(option)),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_view_month_outlined, size: 20),
            const SizedBox(width: 4),
            Text(_label(preset)),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

class _HistoryChartCard extends ConsumerWidget {
  const _HistoryChartCard();

  String _rangeNoun(ExpenseDatePreset preset) => switch (preset) {
        ExpenseDatePreset.today => AppStrings.last7Days,
        ExpenseDatePreset.week => AppStrings.last7Weeks,
        ExpenseDatePreset.month => AppStrings.last7Months,
        ExpenseDatePreset.custom => AppStrings.last7Periods,
      };

  String _axisLabel(ExpenseDatePreset preset, DateTime start) {
    return switch (preset) {
      ExpenseDatePreset.month => DateFormat('MMM').format(start),
      _ => DateFormat('d/M').format(start),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final preset = ref.watch(expenseDateFilterProvider).preset;
    final historyAsync = ref.watch(expenseHistoryProvider);
    final comparisonAsync = ref.watch(expenseComparisonProvider);

    return historyAsync.when(
      loading: () => const Card(
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (points) {
        final maxSpent =
            points.fold<double>(0, (m, p) => p.spent > m ? p.spent : m);
        return Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bar_chart_outlined,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.spendingTrend,
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            _rangeNoun(preset),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    comparisonAsync.maybeWhen(
                      data: (c) => _DeltaBadge(comparison: c),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 170,
                  child: maxSpent <= 0
                      ? Center(
                          child: Text(
                            AppStrings.comparisonNoPrevious,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: maxSpent * 1.25,
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem: (group, _, rod, __) {
                                  return BarTooltipItem(
                                    Formatters.currency(rod.toY),
                                    theme.textTheme.labelMedium!.copyWith(
                                      color: theme.colorScheme.onInverseSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 24,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 || index >= points.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        _axisLabel(
                                          preset,
                                          points[index].range.start,
                                        ),
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barGroups: [
                              for (var i = 0; i < points.length; i++)
                                BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: points[i].spent,
                                      width: 16,
                                      color: points[i].isCurrent
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.primary
                                              .withOpacity(0.32),
                                      borderRadius:
                                          const BorderRadius.vertical(
                                        top: Radius.circular(6),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  const _DeltaBadge({required this.comparison});

  final ExpenseComparison comparison;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = comparison.changeRatio;
    final delta = comparison.delta;

    // No previous spending to compare against.
    if (ratio == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          AppStrings.comparisonNoPrevious,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final increased = delta > 0.0001;
    final decreased = delta < -0.0001;
    // More spending is highlighted as a warning; less spending as positive.
    final color = increased
        ? theme.colorScheme.error
        : decreased
            ? Colors.green.shade700
            : theme.colorScheme.onSurfaceVariant;
    final icon = increased
        ? Icons.arrow_upward
        : decreased
            ? Icons.arrow_downward
            : Icons.remove;
    final percent = '${(ratio.abs() * 100).toStringAsFixed(0)}%';
    final label = (increased || decreased) ? percent : AppStrings.comparisonNoChange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.amount,
    this.emphasized = false,
  });

  final String label;
  final double amount;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.titleMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: ValueText(
              Formatters.currency(amount),
              style: style?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
