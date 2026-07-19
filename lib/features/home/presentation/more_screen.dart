import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/nav_features.dart';
import '../../../shared/providers/record_permissions.dart';
import '../../../shared/utils/shell_navigation.dart';
import '../../../shared/widgets/secret_tap.dart';
import '../../auth/data/auth_repository.dart';
import '../../assistant/presentation/scan_receipt_screen.dart';
import '../../feedback/presentation/feedback_screen.dart';
import '../../household/data/household_settings_repository.dart';
import '../../household/presentation/household_screen.dart';
import '../../settings/presentation/settings_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modules = ref.watch(enabledModulesProvider);
    final theme = Theme.of(context);
    final overflow = NavFeatures.overflowFeatures(modules);

    final overflowItems = overflow
        .map(
          (feature) => _MoreTile(
            icon: feature.icon,
            color: theme.colorScheme.primary,
            title: feature.label,
            subtitle: feature.hint,
            onTap: () => context.go(shellRouteFromMore(feature.path)),
          ),
        )
        .toList();

    final householdItems = <_MoreTile>[
      _MoreTile(
        icon: Icons.family_restroom_outlined,
        color: theme.colorScheme.primary,
        title: AppStrings.householdTitle,
        subtitle: AppStrings.moreFamilyHint,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const HouseholdScreen()),
        ),
      ),
    ];

    final isOwner = ref.watch(isHouseholdOwnerProvider);
    if (isOwner) {
      householdItems.add(
        _MoreTile(
          icon: Icons.restart_alt_outlined,
          color: theme.colorScheme.error,
          title: AppStrings.resetDataTitle,
          subtitle: AppStrings.moreResetHint,
          onTap: () => context.push('/reset-data'),
        ),
      );
    }

    final appItems = <_MoreTile>[
      _MoreTile(
        icon: Icons.receipt_long_outlined,
        color: theme.colorScheme.primary,
        title: AppStrings.assistantTitle,
        subtitle: AppStrings.moreAssistantHint,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ScanReceiptScreen()),
        ),
      ),
      _MoreTile(
        icon: Icons.settings_outlined,
        color: Colors.blueGrey,
        title: AppStrings.settingsTitle,
        subtitle: AppStrings.moreSettingsHint,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
        ),
      ),
      _MoreTile(
        icon: Icons.feedback_outlined,
        color: Colors.green,
        title: AppStrings.feedbackTitle,
        subtitle: AppStrings.moreFeedbackHint,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const FeedbackScreen()),
        ),
      ),
    ];

    final isAdmin =
        ref.watch(userProfileProvider).valueOrNull?.isAdmin ?? false;
    if (isAdmin) {
      appItems.add(
        _MoreTile(
          icon: Icons.admin_panel_settings_outlined,
          color: Colors.deepPurple,
          title: AppStrings.adminTitle,
          subtitle: AppStrings.moreAdminHint,
          onTap: () => context.push('/admin'),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.navMore,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SecretTap(
                      child: Text(
                        AppStrings.moreSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (overflowItems.isNotEmpty)
            _Section(
              title: AppStrings.moreSectionFeatures,
              items: overflowItems,
            ),
          _Section(
            title: AppStrings.moreSectionHousehold,
            items: householdItems,
          ),
          _Section(
            title: AppStrings.moreSectionApp,
            items: appItems,
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.items});

  final String title;
  final List<_MoreTile> items;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              items[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.45),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
