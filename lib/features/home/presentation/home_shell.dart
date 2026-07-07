import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/nav_features.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../household/data/household_settings_repository.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modules = ref.watch(enabledModulesProvider);
    final barFeatures = NavFeatures.bottomBarFeatures(modules);
    final showMore = NavFeatures.showMoreTab(modules);

    final tabs = <_NavTab>[
      const _NavTab(
        branchIndex: NavFeatures.homeBranchIndex,
        destination: NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: AppStrings.navHome,
        ),
      ),
      ...barFeatures.map(
        (feature) => _NavTab(
          branchIndex: feature.branchIndex,
          destination: NavigationDestination(
            icon: Icon(feature.icon),
            selectedIcon: Icon(feature.selectedIcon),
            label: feature.label,
          ),
        ),
      ),
      if (showMore)
        const _NavTab(
          branchIndex: NavFeatures.moreBranchIndex,
          destination: NavigationDestination(
            icon: Icon(Icons.more_horiz_outlined),
            selectedIcon: Icon(Icons.more_horiz),
            label: AppStrings.navMore,
          ),
        ),
    ];

    var selectedIndex = tabs.indexWhere(
      (t) => t.branchIndex == navigationShell.currentIndex,
    );
    if (selectedIndex < 0) selectedIndex = 0;

    return Scaffold(
      body: OfflineBanner(child: navigationShell),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            final tab = tabs[index];
            navigationShell.goBranch(
              tab.branchIndex,
              initialLocation: tab.branchIndex == navigationShell.currentIndex,
            );
          },
          destinations: tabs.map((t) => t.destination).toList(),
        ),
      ),
    );
  }
}

class _NavTab {
  const _NavTab({
    required this.branchIndex,
    required this.destination,
  });

  final int branchIndex;
  final NavigationDestination destination;
}
