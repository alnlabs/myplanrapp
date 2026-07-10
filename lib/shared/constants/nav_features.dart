import 'package:flutter/material.dart';

import '../../core/strings/app_strings.dart';
import 'household_modules.dart';

/// Bottom-nav feature order (after Home).
class NavFeatures {
  NavFeatures._();

  static const maxBottomNavSlots = 4;

  static const ordered = <NavFeature>[
    NavFeature(
      module: HouseholdModules.pantry,
      branchIndex: 1,
      path: '/pantry',
      label: AppStrings.navInventory,
      hint: AppStrings.moreInventoryHint,
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
    ),
    NavFeature(
      module: HouseholdModules.plans,
      branchIndex: 2,
      path: '/plans',
      label: AppStrings.navPlans,
      hint: AppStrings.morePlansHint,
      icon: Icons.event_note_outlined,
      selectedIcon: Icons.event_note,
    ),
    NavFeature(
      module: HouseholdModules.expenses,
      branchIndex: 3,
      path: '/expenses',
      label: AppStrings.navExpenses,
      hint: AppStrings.moreExpensesHint,
      icon: Icons.payments_outlined,
      selectedIcon: Icons.payments,
    ),
    NavFeature(
      module: HouseholdModules.subscriptions,
      branchIndex: 4,
      path: '/subscriptions',
      label: AppStrings.subscriptionsTitle,
      hint: AppStrings.moreSubscriptionsHint,
      icon: Icons.subscriptions_outlined,
      selectedIcon: Icons.subscriptions,
    ),
    NavFeature(
      module: HouseholdModules.shopping,
      branchIndex: 5,
      path: '/shop',
      label: AppStrings.navShop,
      hint: AppStrings.moreShopHint,
      icon: Icons.shopping_cart_outlined,
      selectedIcon: Icons.shopping_cart,
    ),
  ];

  static const homeBranchIndex = 0;
  static const moreBranchIndex = 6;

  /// Enabled features in priority order.
  static List<NavFeature> enabled(Set<String> modules) {
    return ordered.where((f) => _isNavFeatureEnabled(f.module, modules)).toList();
  }

  /// Plans tab covers reminders too — no separate reminders nav item.
  static bool _isNavFeatureEnabled(String module, Set<String> modules) {
    if (module == HouseholdModules.plans) {
      return modules.contains(HouseholdModules.plans) ||
          modules.contains(HouseholdModules.reminders);
    }
    return modules.contains(module);
  }

  /// Whether the More tab is needed (more than 3 feature modules enabled).
  static bool showMoreTab(Set<String> modules) {
    return enabled(modules).length > maxBottomNavSlots - 1;
  }

  /// Features shown directly in the bottom bar beside Home (max 4 slots total).
  static List<NavFeature> bottomBarFeatures(Set<String> modules) {
    final all = enabled(modules);
    const maxFeaturesWithoutMore = maxBottomNavSlots - 1; // Home uses one slot.
    if (all.length <= maxFeaturesWithoutMore) return all;
    // Reserve the last slot for More when features overflow.
    return all.take(maxBottomNavSlots - 2).toList();
  }

  /// Features not in the bottom bar — reachable from More.
  static List<NavFeature> overflowFeatures(Set<String> modules) {
    final all = enabled(modules);
    if (!showMoreTab(modules)) return const [];
    return all.skip(maxBottomNavSlots - 2).toList();
  }
}

class NavFeature {
  const NavFeature({
    required this.module,
    required this.branchIndex,
    required this.path,
    required this.label,
    required this.hint,
    required this.icon,
    required this.selectedIcon,
  });

  final String module;
  final int branchIndex;
  final String path;
  final String label;
  final String hint;
  final IconData icon;
  final IconData selectedIcon;
}
