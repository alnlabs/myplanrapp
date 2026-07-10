import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/utils/offline_guard.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../../auth/data/auth_repository.dart';
import '../data/expense_date_filter_provider.dart';
import '../data/expense_repository.dart';
import '../utils/expense_csv_export.dart';
import '../utils/expense_period_label.dart';
import '../utils/money_report_export.dart';
import 'expense_period_filter_bar.dart';

class ExpenseSummaryScreen extends ConsumerWidget {
  const ExpenseSummaryScreen({super.key});

  Future<void> _exportReport(BuildContext context, WidgetRef ref) async {
    try {
      ref.ensureOnline();
      final profile = await ref.read(userProfileProvider.future);
      final householdId = profile?.activeHouseholdId;
      if (householdId == null) return;
      final range = ref.read(expenseDateRangeProvider);
      final dateFilter = ref.read(expenseDateFilterProvider);
      final all = await ref.read(expenseRepositoryProvider).fetchForExport(
            householdId,
            range.start,
            range.end,
          );
      if (all.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.emptyExport)),
          );
        }
        return;
      }
      final csv = ExpenseCsvExport.build(
        entries: all,
        periodLabel: expensePeriodExportLabel(dateFilter),
        truncated: all.length >= 5000,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseSummaryAsync = ref.watch(expenseSummaryProvider);
    final moneySummaryAsync = ref.watch(moneySummaryProvider);
    final memberIncomeAsync = ref.watch(memberIncomeSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.summaryTitle),
        actions: [
          IconButton(
            onPressed: () => _exportReport(context, ref),
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: AppStrings.exportReport,
          ),
        ],
      ),
      body: AsyncScreenBody(
        value: moneySummaryAsync,
        onRetry: () {
          ref.invalidate(moneySummaryProvider);
          ref.invalidate(expenseSummaryProvider);
          ref.invalidate(memberIncomeSummaryProvider);
        },
        isEmpty: (_) => false,
        builder: (moneySummary) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const ExpensePeriodFilterBar(),
              const SizedBox(height: 12),
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
                            title: Text(row.memberName),
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
                            title: Text(row.categoryName),
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
          Expanded(child: Text(label)),
          Text(
            Formatters.currency(amount),
            style: style?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
