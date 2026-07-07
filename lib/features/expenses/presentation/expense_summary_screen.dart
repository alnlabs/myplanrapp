import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../data/expense_repository.dart';

class ExpenseSummaryScreen extends ConsumerWidget {
  const ExpenseSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(expenseSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.summaryTitle)),
      body: AsyncScreenBody(
        value: summaryAsync,
        onRetry: () => ref.invalidate(expenseSummaryProvider),
        isEmpty: (rows) => rows.isEmpty,
        emptyTitle: AppStrings.emptyExpenses,
        builder: (rows) {
          final total = rows.fold<double>(0, (s, r) => s + r.totalAmount);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  title: const Text(AppStrings.monthlyTotal),
                  subtitle: Text(Formatters.monthYear(DateTime.now())),
                  trailing: Text(
                    Formatters.currency(total),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...rows.map(
                (row) => Card(
                  child: ListTile(
                    title: Text(row.categoryName),
                    trailing: Text(Formatters.currency(row.totalAmount)),
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
