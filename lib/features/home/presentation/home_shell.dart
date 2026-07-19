import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/widgets/offline_banner.dart';
import 'app_drawer.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = <_NavTab>[
    _NavTab(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: AppStrings.navDashboard,
    ),
    _NavTab(
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      label: AppStrings.navInventory,
    ),
    _NavTab(
      icon: Icons.event_note_outlined,
      selectedIcon: Icons.event_note,
      label: AppStrings.navPlans,
    ),
    _NavTab(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: AppStrings.navHome,
    ),
  ];

  void _goBranch(int branchIndex) {
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final current = navigationShell.currentIndex;

    return Scaffold(
      key: rootScaffoldKey,
      drawer: const AppDrawer(),
      body: OfflineBanner(child: navigationShell),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  _NavItem(
                    tab: _tabs[i],
                    selected: current == i,
                    onTap: () => _goBranch(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _NavTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? tab.selectedIcon : tab.icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              tab.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTab {
  const _NavTab({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
