import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/household_modules.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../household/data/household_settings_repository.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modules = ref.watch(enabledModulesProvider);

    final allTabs = <_NavTab>[
      _NavTab(
        branchIndex: 0,
        destination: const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: AppStrings.navHome,
        ),
        isVisible: (_) => true,
      ),
      _NavTab(
        branchIndex: 1,
        destination: const NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: AppStrings.navInventory,
        ),
        isVisible: (m) => m.contains(HouseholdModules.pantry),
      ),
      _NavTab(
        branchIndex: 2,
        destination: const NavigationDestination(
          icon: Icon(Icons.event_note_outlined),
          selectedIcon: Icon(Icons.event_note),
          label: AppStrings.navPlans,
        ),
        isVisible: (m) => m.contains(HouseholdModules.plans),
      ),
      _NavTab(
        branchIndex: 3,
        destination: const NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book),
          label: AppStrings.navRecipes,
        ),
        isVisible: (m) => m.contains(HouseholdModules.recipes),
      ),
      _NavTab(
        branchIndex: 4,
        destination: const NavigationDestination(
          icon: Icon(Icons.more_horiz_outlined),
          selectedIcon: Icon(Icons.more_horiz),
          label: AppStrings.navMore,
        ),
        isVisible: (_) => true,
      ),
    ];

    final visibleTabs = allTabs.where((t) => t.isVisible(modules)).toList();
    var selectedVisibleIndex = visibleTabs.indexWhere(
      (t) => t.branchIndex == navigationShell.currentIndex,
    );
    if (selectedVisibleIndex < 0) selectedVisibleIndex = 0;

    return Scaffold(
      body: OfflineBanner(child: navigationShell),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedVisibleIndex,
        onDestinationSelected: (index) {
          final tab = visibleTabs[index];
          navigationShell.goBranch(
            tab.branchIndex,
            initialLocation: tab.branchIndex == navigationShell.currentIndex,
          );
        },
        destinations: visibleTabs.map((t) => t.destination).toList(),
      ),
    );
  }
}

class _NavTab {
  const _NavTab({
    required this.branchIndex,
    required this.destination,
    required this.isVisible,
  });

  final int branchIndex;
  final NavigationDestination destination;
  final bool Function(Set<String> modules) isVisible;
}
