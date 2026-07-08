import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/household_modules.dart';
import '../../../shared/constants/plan_constants.dart';
import '../../../shared/models/home_asset.dart';
import '../../../shared/models/household.dart';
import '../../../shared/models/pantry_item.dart';
import '../../../shared/models/subscription.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/utils/formatters.dart';
import '../../alerts/presentation/alerts_screen.dart';
import '../../assets/data/asset_repository.dart';
import '../../auth/data/auth_repository.dart';
import '../../expenses/data/expense_repository.dart';
import '../../expenses/presentation/add_expense_screen.dart';
import '../../household/data/household_repository.dart';
import '../../household/data/household_settings_repository.dart';
import '../../household/data/medicine_schedule_repository.dart';
import '../../household/presentation/household_screen.dart';
import '../../pantry/data/pantry_repository.dart';
import '../../plans/data/plan_repository.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../recipes/presentation/recipe_form_screen.dart';
import '../../subscriptions/data/subscription_repository.dart';
import '../data/setup_checklist_provider.dart';
import 'setup_checklist_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.goodMorning;
    if (hour < 17) return AppStrings.goodAfternoon;
    return AppStrings.goodEvening;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final householdAsync = ref.watch(activeHouseholdProvider);
    final modules = ref.watch(enabledModulesProvider);
    final lowStockAsync = ref.watch(lowStockItemsProvider);
    final expiringAsync = ref.watch(expiringItemsProvider);
    final summaryAsync = ref.watch(expenseSummaryProvider);
    final openPlansAsync = ref.watch(openPlansProvider);
    final warrantyAsync = ref.watch(warrantyExpiringAssetsProvider);
    final subsDueSoonAsync = ref.watch(subscriptionsDueSoonProvider);
    final medicineTodayAsync = ref.watch(medicineRemindersTodayProvider);
    final checklistAsync = ref.watch(setupChecklistProvider);

    final showExpenses = modules.contains(HouseholdModules.expenses);
    final showPlans = modules.contains(HouseholdModules.plans);
    final showAssets = modules.contains(HouseholdModules.assets);
    final showPantry = modules.contains(HouseholdModules.pantry);
    final showRecipes = modules.contains(HouseholdModules.recipes);
    final showSubscriptions = modules.contains(HouseholdModules.subscriptions);

    final showTodaySection =
        showPlans || (medicineTodayAsync.valueOrNull?.isNotEmpty ?? false);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _DashboardHeader(
                    greeting: _greeting(),
                    profileAsync: profileAsync,
                    householdAsync: householdAsync,
                    onProfile: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
                    ),
                    onFamily: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const HouseholdScreen()),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverToBoxAdapter(
                child: _QuickActionsGrid(
                  showPlans: showPlans,
                  showPantry: showPantry,
                  showExpenses: showExpenses,
                  showRecipes: showRecipes,
                  showSubscriptions: showSubscriptions,
                  onAddPlan: () => context.push('/plans/add'),
                  onAddItem: () => context.push('/pantry/add'),
                  onAddExpense: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const AddExpenseScreen()),
                  ),
                  onAddRecipe: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const RecipeFormScreen()),
                  ),
                  onAddSubscription: () => context.push('/subscriptions/add'),
                  onShop: () => context.go('/shop'),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: checklistAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (checklist) {
                    if (checklist == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SetupChecklistCard(checklist: checklist),
                    );
                  },
                ),
              ),
            ),
            if (showExpenses)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: summaryAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: LinearProgressIndicator(),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (rows) {
                      final total =
                          rows.fold<double>(0, (s, r) => s + r.totalAmount);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _SummaryCard(
                          label: AppStrings.monthlyTotal,
                          value: Formatters.currency(total),
                          subtitle: Formatters.monthYear(DateTime.now()),
                          icon: Icons.payments_outlined,
                          onTap: () => context.go('/expenses'),
                        ),
                      );
                    },
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: _AttentionSection(
                  showPantry: showPantry,
                  showAssets: showAssets,
                  showSubscriptions: showSubscriptions,
                  lowStockAsync: lowStockAsync,
                  expiringAsync: expiringAsync,
                  warrantyAsync: warrantyAsync,
                  subsDueSoonAsync: subsDueSoonAsync,
                  onAlerts: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const AlertsScreen()),
                  ),
                  onPantry: () => context.go('/pantry'),
                  onSubscriptions: () => context.go('/subscriptions'),
                ),
              ),
            ),
            if (showTodaySection) ...[
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: _SectionTitle(title: AppStrings.todayOverview),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: medicineTodayAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (reminders) {
                    if (reminders.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TodayCard(
                        icon: Icons.medication_outlined,
                        title: AppStrings.medicineToday,
                        subtitle:
                            '${reminders.length} dose${reminders.length == 1 ? '' : 's'} today',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const HouseholdScreen(),
                          ),
                        ),
                        moreCount: reminders.length > 3 ? reminders.length - 3 : 0,
                        children: reminders.take(3).map((item) {
                          return _TodayRow(
                            title: item.medicineName,
                            subtitle: [
                              item.timeLabel,
                              item.memberName,
                              if (item.dosage != null) item.dosage!,
                            ].join(' · '),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (showPlans)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: openPlansAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (plans) {
                      final sorted = [...plans]
                        ..sort((a, b) {
                          if (a.dueAt == null && b.dueAt == null) return 0;
                          if (a.dueAt == null) return 1;
                          if (b.dueAt == null) return -1;
                          return a.dueAt!.compareTo(b.dueAt!);
                        });
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _TodayCard(
                          icon: Icons.event_note_outlined,
                          title: AppStrings.openPlans,
                          subtitle: plans.isEmpty
                              ? AppStrings.noOpenPlans
                              : '${plans.length} open',
                          onTap: () => context.go('/plans'),
                          moreCount: plans.length > 3 ? plans.length - 3 : 0,
                          emptyText: AppStrings.noOpenPlans,
                          children: sorted.take(3).map((plan) {
                            return _TodayRow(
                              title: plan.title,
                              subtitle: [
                                PlanTypes.labelFor(plan.planType),
                                if (plan.dueAt != null)
                                  Formatters.dateTime(plan.dueAt!),
                              ].join(' · '),
                              icon: _planIcon(plan.planType),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(activeHouseholdProvider);
    ref.invalidate(userProfileProvider);
    ref.invalidate(lowStockItemsProvider);
    ref.invalidate(expiringItemsProvider);
    ref.invalidate(expenseSummaryProvider);
    ref.invalidate(openPlansProvider);
    ref.invalidate(warrantyExpiringAssetsProvider);
    ref.invalidate(subscriptionsDueSoonProvider);
    ref.invalidate(medicineRemindersTodayProvider);
    ref.invalidate(setupChecklistProvider);
  }

  static IconData _planIcon(String type) => switch (type) {
        PlanTypes.purchase => Icons.shopping_bag_outlined,
        PlanTypes.meal => Icons.restaurant_outlined,
        PlanTypes.medicine => Icons.medication_outlined,
        PlanTypes.bill => Icons.receipt_long_outlined,
        PlanTypes.appointment => Icons.event_available_outlined,
        PlanTypes.event => Icons.celebration_outlined,
        PlanTypes.travel => Icons.flight_takeoff_outlined,
        PlanTypes.chore => Icons.cleaning_services_outlined,
        PlanTypes.maintenance => Icons.build_outlined,
        PlanTypes.birthday => Icons.cake_outlined,
        PlanTypes.school => Icons.school_outlined,
        PlanTypes.pet => Icons.pets_outlined,
        _ => Icons.task_alt_outlined,
      };
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.greeting,
    required this.profileAsync,
    required this.householdAsync,
    required this.onProfile,
    required this.onFamily,
  });

  final String greeting;
  final AsyncValue<UserProfile?> profileAsync;
  final AsyncValue<Household?> householdAsync;
  final VoidCallback onProfile;
  final VoidCallback onFamily;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = profileAsync.valueOrNull;
    final name = profile?.displayName ?? profile?.username;
    final household = householdAsync.valueOrNull?.name;
    final today = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  greeting,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(0.85),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onProfile,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.person_outline,
                      color: theme.colorScheme.onPrimary,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            name ?? AppStrings.appName,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            today,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withOpacity(0.8),
            ),
          ),
          if (household != null) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: onFamily,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.family_restroom_outlined,
                      size: 16,
                      color: theme.colorScheme.onPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      household,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    required this.showPlans,
    required this.showPantry,
    required this.showExpenses,
    required this.showRecipes,
    required this.showSubscriptions,
    required this.onAddPlan,
    required this.onAddItem,
    required this.onAddExpense,
    required this.onAddRecipe,
    required this.onAddSubscription,
    required this.onShop,
  });

  final bool showPlans;
  final bool showPantry;
  final bool showExpenses;
  final bool showRecipes;
  final bool showSubscriptions;
  final VoidCallback onAddPlan;
  final VoidCallback onAddItem;
  final VoidCallback onAddExpense;
  final VoidCallback onAddRecipe;
  final VoidCallback onAddSubscription;
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    final actions = <({IconData icon, String label, VoidCallback onTap})>[
      if (showPlans) (icon: Icons.event_note_outlined, label: AppStrings.quickActionPlan, onTap: onAddPlan),
      if (showPantry) (icon: Icons.kitchen_outlined, label: AppStrings.quickActionPantry, onTap: onAddItem),
      if (showPantry) (icon: Icons.shopping_cart_outlined, label: AppStrings.quickActionShop, onTap: onShop),
      if (showExpenses) (icon: Icons.payments_outlined, label: AppStrings.quickActionExpense, onTap: onAddExpense),
      if (showRecipes) (icon: Icons.menu_book_outlined, label: AppStrings.quickActionRecipe, onTap: onAddRecipe),
      if (showSubscriptions) (icon: Icons.subscriptions_outlined, label: AppStrings.quickActionSubscription, onTap: onAddSubscription),
    ];

    if (actions.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[];
    for (var i = 0; i < actions.length; i += 2) {
      final left = actions[i];
      final right = i + 1 < actions.length ? actions[i + 1] : null;
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
          child: Row(
            children: [
              Expanded(
                child: _QuickActionTile(
                  icon: left.icon,
                  label: left.label,
                  onTap: left.onTap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: right == null
                    ? const SizedBox.shrink()
                    : _QuickActionTile(
                        icon: right.icon,
                        label: right.label,
                        onTap: right.onTap,
                      ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: AppStrings.quickActions),
        const SizedBox(height: 8),
        ...rows,
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withOpacity(0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.labelLarge),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttentionSection extends StatelessWidget {
  const _AttentionSection({
    required this.showPantry,
    required this.showAssets,
    required this.showSubscriptions,
    required this.lowStockAsync,
    required this.expiringAsync,
    required this.warrantyAsync,
    required this.subsDueSoonAsync,
    required this.onAlerts,
    required this.onPantry,
    required this.onSubscriptions,
  });

  final bool showPantry;
  final bool showAssets;
  final bool showSubscriptions;
  final AsyncValue<List<PantryItem>> lowStockAsync;
  final AsyncValue<List<PantryItem>> expiringAsync;
  final AsyncValue<List<HomeAsset>> warrantyAsync;
  final AsyncValue<List<Subscription>> subsDueSoonAsync;
  final VoidCallback onAlerts;
  final VoidCallback onPantry;
  final VoidCallback onSubscriptions;

  @override
  Widget build(BuildContext context) {
    final items = <_AttentionItem>[];

    if (showPantry) {
      final lowStock = lowStockAsync.valueOrNull ?? [];
      if (lowStock.isNotEmpty) {
        items.add(_AttentionItem(
          icon: Icons.warning_amber_rounded,
          color: Colors.amber.shade800,
          title: AppStrings.alertsTitle,
          subtitle: '${lowStock.length} low stock item${lowStock.length == 1 ? '' : 's'}',
          onTap: onAlerts,
        ));
      }
      final expiring = expiringAsync.valueOrNull ?? [];
      if (expiring.isNotEmpty) {
        items.add(_AttentionItem(
          icon: Icons.event_busy_outlined,
          color: Colors.orange.shade800,
          title: AppStrings.expiringSoon,
          subtitle: '${expiring.length} item${expiring.length == 1 ? '' : 's'} expiring',
          onTap: onPantry,
        ));
      }
    }

    if (showAssets) {
      final warranty = warrantyAsync.valueOrNull ?? [];
      if (warranty.isNotEmpty) {
        items.add(_AttentionItem(
          icon: Icons.verified_outlined,
          color: Colors.amber.shade800,
          title: AppStrings.warrantyExpiringTitle,
          subtitle:
              '${warranty.length} ${warranty.length == 1 ? 'warranty' : 'warranties'} expiring',
          onTap: onPantry,
        ));
      }
    }

    if (showSubscriptions) {
      final subs = subsDueSoonAsync.valueOrNull ?? [];
      if (subs.isNotEmpty) {
        items.add(_AttentionItem(
          icon: Icons.subscriptions_outlined,
          color: Theme.of(context).colorScheme.error,
          title: AppStrings.subscriptionsDueSoon,
          subtitle: subs.map((s) => s.name).take(2).join(', ') +
              (subs.length > 2 ? '…' : ''),
          onTap: onSubscriptions,
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: AppStrings.needsAttention),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.allClear,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AttentionTile(item: item),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _AttentionItem {
  const _AttentionItem({
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
}

class _AttentionTile extends StatelessWidget {
  const _AttentionTile({required this.item});

  final _AttentionItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                ),
              ),
              Expanded(
                child: ListTile(
                  leading: Icon(item.icon, color: item.color),
                  title: Text(item.title),
                  subtitle: Text(item.subtitle),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.children,
    this.moreCount = 0,
    this.emptyText,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final List<Widget> children;
  final int moreCount;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: theme.colorScheme.primary),
            title: Text(title, style: theme.textTheme.titleSmall),
            subtitle: Text(subtitle),
            trailing: TextButton(
              onPressed: onTap,
              child: const Text(AppStrings.viewAll),
            ),
          ),
          if (children.isEmpty && emptyText != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  emptyText!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            )
          else ...[
            const Divider(height: 1),
            ...children,
            if (moreCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '+ $moreCount more',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TodayRow extends StatelessWidget {
  const _TodayRow({
    required this.title,
    required this.subtitle,
    this.icon,
  });

  final String title;
  final String subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: icon != null
          ? Icon(icon, size: 20, color: Theme.of(context).colorScheme.outline)
          : null,
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
