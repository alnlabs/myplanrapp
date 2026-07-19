import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/strings/app_strings.dart';

/// Toggleable, reorderable dashboard cards. The greeting ("wishing") header,
/// device blockers banner, and setup checklist are always shown at the top and
/// are not listed here.
enum DashboardWidgetId {
  expensesSummary,
  needsAttention,
  medicineToday,
  todayMeals,
  openPlans,
}

extension DashboardWidgetIdX on DashboardWidgetId {
  String get label => switch (this) {
        DashboardWidgetId.expensesSummary => AppStrings.dashboardExpensesCard,
        DashboardWidgetId.needsAttention => AppStrings.needsAttention,
        DashboardWidgetId.medicineToday => AppStrings.medicineToday,
        DashboardWidgetId.todayMeals => AppStrings.todayEatPlan,
        DashboardWidgetId.openPlans => AppStrings.openPlans,
      };
}

/// Ordering + visibility of the dashboard's content cards.
class DashboardLayout {
  const DashboardLayout({required this.order, required this.hidden});

  final List<DashboardWidgetId> order;
  final Set<DashboardWidgetId> hidden;

  bool isVisible(DashboardWidgetId id) => !hidden.contains(id);

  static const defaultLayout = DashboardLayout(
    order: DashboardWidgetId.values,
    hidden: <DashboardWidgetId>{},
  );
}

const _orderKey = 'dashboard_widget_order_v2';
const _hiddenKey = 'dashboard_hidden_widgets_v2';

class DashboardLayoutNotifier extends StateNotifier<DashboardLayout> {
  DashboardLayoutNotifier() : super(DashboardLayout.defaultLayout) {
    _load();
  }

  DashboardWidgetId? _parse(String name) {
    for (final id in DashboardWidgetId.values) {
      if (id.name == name) return id;
    }
    return null;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final storedOrder = prefs.getStringList(_orderKey);
      var order = DashboardWidgetId.values.toList();
      if (storedOrder != null) {
        final parsed = storedOrder
            .map(_parse)
            .whereType<DashboardWidgetId>()
            .toList();
        // Keep any cards not present in the stored order (e.g. added in a
        // newer release) by appending them in their declaration order.
        final missing =
            DashboardWidgetId.values.where((e) => !parsed.contains(e));
        order = [...parsed, ...missing];
      }

      final storedHidden = prefs.getStringList(_hiddenKey) ?? const [];
      final hidden =
          storedHidden.map(_parse).whereType<DashboardWidgetId>().toSet();

      state = DashboardLayout(order: order, hidden: hidden);
    } catch (_) {}
  }

  Future<void> _persist(DashboardLayout layout) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _orderKey,
        layout.order.map((e) => e.name).toList(),
      );
      await prefs.setStringList(
        _hiddenKey,
        layout.hidden.map((e) => e.name).toList(),
      );
    } catch (_) {}
  }

  Future<void> setVisible(DashboardWidgetId id, bool visible) async {
    final hidden = {...state.hidden};
    if (visible) {
      hidden.remove(id);
    } else {
      hidden.add(id);
    }
    final next = DashboardLayout(order: state.order, hidden: hidden);
    state = next;
    await _persist(next);
  }

  /// Applies a new ordering for the dashboard cards.
  Future<void> reorder(List<DashboardWidgetId> newOrder) async {
    final rest = state.order.where((e) => !newOrder.contains(e));
    final order = [...newOrder, ...rest];
    final next = DashboardLayout(order: order, hidden: state.hidden);
    state = next;
    await _persist(next);
  }
}

final dashboardLayoutProvider =
    StateNotifierProvider<DashboardLayoutNotifier, DashboardLayout>(
  (ref) => DashboardLayoutNotifier(),
);
