import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../assistant/presentation/receipts_list_screen.dart';
import '../../auth/data/auth_repository.dart';
import '../../household/data/household_repository.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import 'help_info_screen.dart';

/// Key for the shell [Scaffold] that hosts the [AppDrawer], so any screen can
/// open the sidebar on top of the whole app (including the bottom bar).
final rootScaffoldKey = GlobalKey<ScaffoldState>();

/// Opens the app-wide sidebar drawer regardless of the current screen.
void openAppDrawer() => rootScaffoldKey.currentState?.openDrawer();

/// Hamburger button that opens the app-wide [AppDrawer].
class DrawerMenuButton extends StatelessWidget {
  const DrawerMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu),
      tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      onPressed: openAppDrawer,
    );
  }
}

/// Hamburger sidebar with all secondary features, settings, and info links.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  void _go(BuildContext context, String route) {
    Navigator.of(context).pop();
    context.push(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final household = ref.watch(activeHouseholdProvider).valueOrNull;
    final isAdmin = profile?.isAdmin ?? false;

    return Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _DrawerHeader(
              name: profile?.displayName ?? profile?.username ?? AppStrings.appName,
              familyName: household?.name,
              onTap: () => _push(context, const ProfileScreen()),
            ),
            const _SectionLabel(label: AppStrings.moreSectionFeatures),
            _DrawerTile(
              icon: Icons.payments_outlined,
              title: AppStrings.navExpenses,
              subtitle: AppStrings.moreExpensesHint,
              onTap: () => _go(context, '/expenses'),
            ),
            _DrawerTile(
              icon: Icons.subscriptions_outlined,
              title: AppStrings.subscriptionsTitle,
              subtitle: AppStrings.moreSubscriptionsHint,
              onTap: () => _go(context, '/subscriptions'),
            ),
            _DrawerTile(
              icon: Icons.shopping_cart_outlined,
              title: AppStrings.navShop,
              subtitle: AppStrings.moreShopHint,
              onTap: () => _go(context, '/shop'),
            ),
            _DrawerTile(
              icon: Icons.receipt_long_outlined,
              title: AppStrings.drawerReceipts,
              subtitle: AppStrings.drawerReceiptsHint,
              onTap: () => _push(context, const ReceiptsListScreen()),
            ),
            const Divider(),
            const _SectionLabel(label: AppStrings.moreSectionApp),
            _DrawerTile(
              icon: Icons.settings_outlined,
              title: AppStrings.settingsTitle,
              subtitle: AppStrings.moreSettingsHint,
              onTap: () => _push(context, const SettingsScreen()),
            ),
            _DrawerTile(
              icon: Icons.help_outline,
              title: AppStrings.helpInfoTitle,
              subtitle: AppStrings.helpInfoHint,
              onTap: () => _push(context, const HelpInfoScreen()),
            ),
            if (isAdmin)
              _DrawerTile(
                icon: Icons.admin_panel_settings_outlined,
                title: AppStrings.adminTitle,
                subtitle: AppStrings.moreAdminHint,
                onTap: () => _go(context, '/admin'),
              ),
            const Divider(),
            _DrawerTile(
              icon: Icons.logout,
              title: AppStrings.signOut,
              onTap: () => _signOut(context, ref),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '${AppStrings.appName} ${AppStrings.appVersion}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.signOutConfirmTitle),
        content: const Text(AppStrings.signOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(AppStrings.signOut),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(authRepositoryProvider).signOut();
    if (context.mounted) {
      Navigator.of(context).pop();
      context.go('/login');
    }
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.name,
    required this.familyName,
    required this.onTap,
  });

  final String name;
  final String? familyName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.2),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (familyName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      familyName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimary.withOpacity(0.85),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onPrimary.withOpacity(0.85),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      onTap: onTap,
    );
  }
}
