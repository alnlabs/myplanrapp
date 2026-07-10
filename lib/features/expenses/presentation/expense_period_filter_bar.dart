import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../data/expense_date_filter.dart';
import '../data/expense_date_filter_provider.dart';
import '../data/expenses_list_provider.dart';
import '../utils/expense_period_label.dart';

class ExpensePeriodFilterBar extends ConsumerWidget {
  const ExpensePeriodFilterBar({super.key});

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }

    ref.read(expenseDateFilterProvider.notifier).setCustomRange(
          picked.start,
          picked.end,
        );
    await ref.read(expensesListProvider.notifier).refresh();
  }

  Future<void> _setPreset(
    WidgetRef ref,
    ExpenseDatePreset preset,
    BuildContext context,
  ) async {
    if (preset == ExpenseDatePreset.custom) {
      await _pickCustomRange(context, ref);
      return;
    }
    ref.read(expenseDateFilterProvider.notifier).setPreset(preset);
    await ref.read(expensesListProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(expenseDateFilterProvider);
    final label = expensePeriodLabel(filter);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text(AppStrings.periodToday),
              selected: filter.preset == ExpenseDatePreset.today,
              onSelected: (_) =>
                  _setPreset(ref, ExpenseDatePreset.today, context),
            ),
            ChoiceChip(
              label: const Text(AppStrings.periodThisWeek),
              selected: filter.preset == ExpenseDatePreset.week,
              onSelected: (_) =>
                  _setPreset(ref, ExpenseDatePreset.week, context),
            ),
            ChoiceChip(
              label: const Text(AppStrings.periodThisMonth),
              selected: filter.preset == ExpenseDatePreset.month,
              onSelected: (_) =>
                  _setPreset(ref, ExpenseDatePreset.month, context),
            ),
            ChoiceChip(
              label: Text(
                filter.preset == ExpenseDatePreset.custom
                    ? AppStrings.periodCustom
                    : AppStrings.periodCustomRange,
              ),
              selected: filter.preset == ExpenseDatePreset.custom,
              onSelected: (_) =>
                  _setPreset(ref, ExpenseDatePreset.custom, context),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
