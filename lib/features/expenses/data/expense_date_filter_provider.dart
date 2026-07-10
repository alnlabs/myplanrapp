import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'expense_date_filter.dart';

class ExpenseDateFilterNotifier extends Notifier<ExpenseDateFilter> {
  @override
  ExpenseDateFilter build() => const ExpenseDateFilter();

  void setPreset(ExpenseDatePreset preset) {
    state = state.copyWith(preset: preset);
  }

  void setCustomRange(DateTime start, DateTime end) {
    state = ExpenseDateFilter(
      preset: ExpenseDatePreset.custom,
      customStart: start,
      customEnd: end,
    );
  }
}

final expenseDateFilterProvider =
    NotifierProvider<ExpenseDateFilterNotifier, ExpenseDateFilter>(
  ExpenseDateFilterNotifier.new,
);

final expenseDateRangeProvider = Provider<ExpenseDateRange>((ref) {
  return ref.watch(expenseDateFilterProvider).rangeFor();
});
