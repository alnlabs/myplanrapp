import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/household_modules.dart';
import '../../household/data/household_settings_repository.dart';
import '../../household/presentation/household_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modules = ref.watch(enabledModulesProvider);

    final items = <_MoreItem>[
      if (modules.contains(HouseholdModules.expenses))
        _MoreItem(
          icon: Icons.payments_outlined,
          title: AppStrings.navExpenses,
          subtitle: AppStrings.moreExpensesHint,
          route: '/more/expenses',
        ),
      if (modules.contains(HouseholdModules.shopping))
        _MoreItem(
          icon: Icons.shopping_cart_outlined,
          title: AppStrings.navShop,
          subtitle: AppStrings.moreShopHint,
          route: '/more/shop',
        ),
      if (modules.contains(HouseholdModules.subscriptions))
        _MoreItem(
          icon: Icons.subscriptions_outlined,
          title: AppStrings.subscriptionsTitle,
          subtitle: AppStrings.moreSubscriptionsHint,
          route: '/more/subscriptions',
        ),
      _MoreItem(
        icon: Icons.family_restroom_outlined,
        title: AppStrings.householdTitle,
        subtitle: AppStrings.moreFamilyHint,
        route: null,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const HouseholdScreen()),
        ),
      ),
      _MoreItem(
        icon: Icons.person_outline,
        title: AppStrings.profileTitle,
        subtitle: AppStrings.moreProfileHint,
        route: null,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.navMore)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            AppStrings.moreSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Card(
              child: ListTile(
                leading: Icon(item.icon),
                title: Text(item.title),
                subtitle: Text(item.subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: item.onTap ??
                    () {
                      if (item.route != null) context.go(item.route!);
                    },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreItem {
  const _MoreItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.route,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? route;
  final VoidCallback? onTap;
}
