import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/strings/app_strings.dart';
import '../utils/dashboard_greeting.dart';
import '../../../shared/constants/meal_slots.dart';
import '../../../shared/constants/plan_constants.dart';
import '../../../shared/models/home_asset.dart';
import '../../../shared/models/household.dart';
import '../../../shared/models/pantry_item.dart';
import '../../../shared/models/plan.dart';
import '../../../shared/models/subscription.dart';
import '../../../shared/models/user_profile.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/value_text.dart';
import '../../alerts/presentation/alerts_screen.dart';
import '../../assets/data/asset_repository.dart';
import '../../auth/data/auth_repository.dart';
import '../../expenses/data/expense_repository.dart';
import '../../household/data/family_repository.dart';
import '../../household/data/household_repository.dart';
import '../../household/data/medicine_dose_tracker.dart';
import '../../household/data/medicine_schedule_repository.dart';
import '../../household/presentation/household_screen.dart';
import '../../pantry/data/pantry_repository.dart';
import '../../plans/data/plan_repository.dart';
import '../../plans/presentation/plan_detail_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../subscriptions/data/subscription_repository.dart';
import '../../settings/data/device_permissions.dart';
import '../../settings/presentation/device_permissions_screen.dart';
import '../data/setup_checklist_provider.dart';
import '../data/dashboard_layout_provider.dart';
import '../utils/dashboard_attention_groups.dart';
import 'add_sheet.dart';
import 'app_drawer.dart';
import 'dashboard_customize_sheet.dart';
import 'setup_checklist_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final householdAsync = ref.watch(activeHouseholdProvider);
    final layout = ref.watch(dashboardLayoutProvider);

    Widget cardFor(DashboardWidgetId id) {
      switch (id) {
        case DashboardWidgetId.expensesSummary:
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _DashboardExpensesSummary(),
          );
        case DashboardWidgetId.needsAttention:
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _AttentionSection(
              onAlerts: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AlertsScreen()),
              ),
              onPantry: () => context.go('/pantry'),
              onAssets: () => context.go('/pantry?segment=assets'),
              onSubscriptions: () => context.push('/subscriptions'),
            ),
          );
        case DashboardWidgetId.medicineToday:
          return const _DashboardMedicineToday();
        case DashboardWidgetId.todayMeals:
          return const _DashboardTodayMeals();
        case DashboardWidgetId.openPlans:
          return const _DashboardOpenPlans();
      }
    }

    final cards = <Widget>[
      for (final id in layout.order)
        if (layout.isVisible(id)) cardFor(id),
    ];

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddSheet(context),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addSheetTitle),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: _DashboardHeader(
                    greeting: dashboardGreeting(),
                    profileAsync: profileAsync,
                    householdAsync: householdAsync,
                    onProfile: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
                    ),
                    onFamily: () => context.go('/family'),
                    onCustomize: () => showDashboardCustomizeSheet(context),
                  ),
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              sliver: SliverToBoxAdapter(
                child: _DashboardDeviceBlockersBanner(),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(child: _DashboardSetupChecklist()),
            ),
            for (final card in cards) SliverToBoxAdapter(child: card),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 88 + MediaQuery.of(context).padding.bottom,
              ),
            ),
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
    ref.invalidate(openPlansOverviewProvider);
    ref.invalidate(todayMealPlansProvider);
    ref.invalidate(warrantyExpiringAssetsProvider);
    ref.invalidate(subscriptionsDueSoonProvider);
    ref.invalidate(medicineRemindersTodayProvider);
    ref.invalidate(medicineDosesTakenTodayProvider);
    ref.invalidate(setupChecklistDismissedProvider);
    ref.invalidate(setupChecklistProvider);
    ref.invalidate(deviceReminderBlockersProvider);
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
    required this.onCustomize,
  });

  final String greeting;
  final AsyncValue<UserProfile?> profileAsync;
  final AsyncValue<Household?> householdAsync;
  final VoidCallback onProfile;
  final VoidCallback onFamily;
  final VoidCallback onCustomize;

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  greeting,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(0.85),
                  ),
                ),
              ),
              _HeaderIconButton(
                icon: Icons.tune,
                tooltip: AppStrings.customizeDashboard,
                onTap: onCustomize,
              ),
              _HeaderIconButton(
                icon: Icons.person_outline,
                tooltip: AppStrings.profileTitle,
                onTap: onProfile,
              ),
              const _HeaderIconButton(
                icon: Icons.menu,
                tooltip: AppStrings.menu,
                onTap: openAppDrawer,
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

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              color: theme.colorScheme.onPrimary,
              size: 22,
            ),
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
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge,
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: ValueText(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
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

class _AttentionSection extends ConsumerWidget {
  const _AttentionSection({
    required this.onAlerts,
    required this.onPantry,
    required this.onAssets,
    required this.onSubscriptions,
  });

  final VoidCallback onAlerts;
  final VoidCallback onPantry;
  final VoidCallback onAssets;
  final VoidCallback onSubscriptions;

  List<_AttentionGroup> _buildGroups(
    BuildContext context, {
    required List<PantryItem> lowStock,
    required List<PantryItem> expiring,
    required List<HomeAsset> warranty,
    required List<Subscription> subs,
  }) {
    final data = buildDashboardAttentionGroups(
      showPantry: true,
      showAssets: true,
      showSubscriptions: true,
      lowStock: lowStock,
      expiring: expiring,
      warranty: warranty,
      subs: subs,
    );

    Color colorForKind(String kind) => switch (kind) {
          'low_stock' => Colors.amber.shade800,
          'expiring' => Colors.deepOrange.shade700,
          'warranty' => Colors.amber.shade800,
          'subscriptions' => Theme.of(context).colorScheme.error,
          _ => Theme.of(context).colorScheme.primary,
        };

    IconData iconForKind(String kind) => switch (kind) {
          'low_stock' => Icons.inventory_2_outlined,
          'expiring' => Icons.event_busy_outlined,
          'warranty' => Icons.verified_outlined,
          'subscriptions' => Icons.subscriptions_outlined,
          _ => Icons.info_outline,
        };

    VoidCallback onTapForKind(String kind) => switch (kind) {
          'low_stock' => onAlerts,
          'expiring' => onPantry,
          'warranty' => onAssets,
          'subscriptions' => onSubscriptions,
          _ => onAlerts,
        };

    return data
        .map(
          (group) => _AttentionGroup(
            icon: iconForKind(group.kind),
            color: colorForKind(group.kind),
            title: group.title,
            previews: group.previews,
            totalCount: group.totalCount,
            onTap: onTapForKind(group.kind),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lowStock =
        ref.watch(lowStockItemsProvider).valueOrNull ?? const <PantryItem>[];
    final expiring =
        ref.watch(expiringItemsProvider).valueOrNull ?? const <PantryItem>[];
    final warranty = ref.watch(warrantyExpiringAssetsProvider).valueOrNull ??
        const <HomeAsset>[];
    final subs = ref.watch(subscriptionsDueSoonProvider).valueOrNull ??
        const <Subscription>[];

    final groups = _buildGroups(
      context,
      lowStock: lowStock,
      expiring: expiring,
      warranty: warranty,
      subs: subs,
    );
    final totalCount =
        groups.fold<int>(0, (sum, group) => sum + group.totalCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: _SectionTitle(title: AppStrings.needsAttention),
            ),
            if (totalCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$totalCount',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (groups.isEmpty)
          const _AttentionEmptyState()
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < groups.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _AttentionGroupTile(group: groups[i]),
                ],
              ],
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _AttentionGroup {
  const _AttentionGroup({
    required this.icon,
    required this.color,
    required this.title,
    required this.previews,
    required this.totalCount,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final List<String> previews;
  final int totalCount;
  final VoidCallback onTap;
}

class _AttentionGroupTile extends StatelessWidget {
  const _AttentionGroupTile({required this.group});

  final _AttentionGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moreCount = group.totalCount - group.previews.length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: group.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: group.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(group.icon, color: group.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: group.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${group.totalCount}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: group.color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...group.previews.map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          line,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    if (moreCount > 0)
                      Text(
                        AppStrings.attentionMore(moreCount),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttentionEmptyState extends StatelessWidget {
  const _AttentionEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.attentionAllSetTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.attentionAllSetSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
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

class _MedicineTodayCard extends ConsumerWidget {
  const _MedicineTodayCard({
    required this.reminders,
    required this.takenKeys,
    required this.pendingCount,
    required this.takenCount,
    required this.selfMemberId,
  });

  final List<MedicineReminderToday> reminders;
  final Set<String> takenKeys;
  final int pendingCount;
  final int takenCount;
  final String? selfMemberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subtitle = takenCount == 0
        ? '${reminders.length} dose${reminders.length == 1 ? '' : 's'} today'
        : '$pendingCount left · $takenCount taken';

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.medication_outlined, color: theme.colorScheme.primary),
            title: Text(AppStrings.medicineToday, style: theme.textTheme.titleSmall),
            subtitle: Text(subtitle),
            trailing: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const HouseholdScreen(),
                ),
              ),
              child: const Text(AppStrings.viewAll),
            ),
          ),
          const Divider(height: 1),
          ...reminders.take(5).map((item) {
            final doseKey =
                MedicineDoseTracker.doseKey(item.scheduleId, item.timeIndex);
            final taken = takenKeys.contains(doseKey);
            final memberTag = selfMemberId != null &&
                    item.familyMemberId == selfMemberId
                ? AppStrings.tagMe
                : item.memberName;
            final subtitleText = [
              memberTag,
              item.timeLabel,
              if (item.dosage != null) item.dosage!,
            ].join(' · ');

            return CheckboxListTile(
              dense: true,
              value: taken,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                item.displayTitle,
                style: taken
                    ? theme.textTheme.bodyMedium?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: theme.colorScheme.outline,
                      )
                    : null,
              ),
              subtitle: Text(subtitleText),
              onChanged: (checked) async {
                await markMedicineDoseTaken(
                  ref,
                  scheduleId: item.scheduleId,
                  timeIndex: item.timeIndex,
                  taken: checked ?? false,
                );
              },
            );
          }),
          if (reminders.length > 5)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '+ ${reminders.length - 5} more',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TodayEatPlanCard extends StatelessWidget {
  const _TodayEatPlanCard({required this.meals});

  final List<Plan> meals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = groupTodayMealsBySlot(meals);
    final unassigned = unassignedTodayMeals(meals);
    final plannedCount = MealSlots.primary
        .where((slot) => (grouped[slot]?.isNotEmpty ?? false))
        .length;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.restaurant_outlined, color: theme.colorScheme.primary),
            title: Text(AppStrings.todayEatPlan, style: theme.textTheme.titleSmall),
            subtitle: Text(
              plannedCount == 0
                  ? AppStrings.mealNotPlanned
                  : '$plannedCount of ${MealSlots.primary.length} planned',
            ),
            trailing: TextButton(
              onPressed: () => context.go('/plans'),
              child: const Text(AppStrings.viewAll),
            ),
          ),
          const Divider(height: 1),
          ...MealSlots.primary.map((slot) {
            final slotMeals = grouped[slot] ?? const <Plan>[];
            final plan = slotMeals.isNotEmpty ? slotMeals.first : null;
            final extraCount = slotMeals.length > 1 ? slotMeals.length - 1 : 0;
            final slotLabel = MealSlots.labelFor(slot);

            return ListTile(
              dense: true,
              leading: Icon(
                _mealSlotIcon(slot),
                size: 20,
                color: plan != null
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              title: Text(slotLabel),
              subtitle: Text(
                plan != null
                    ? [
                        plan.title,
                        if (extraCount > 0) AppStrings.attentionMore(extraCount),
                      ].join(' · ')
                    : AppStrings.mealNotPlanned,
              ),
              trailing: Icon(
                plan != null ? Icons.chevron_right : Icons.add,
                size: 20,
                color: theme.colorScheme.outline,
              ),
              onTap: () {
                if (plan != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PlanDetailScreen(planId: plan.id),
                    ),
                  );
                } else {
                  context.push('/plans/add?type=meal&slot=$slot');
                }
              },
            );
          }),
          if (unassigned.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.mealUnassigned,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...unassigned.take(2).map(
                        (plan) => Text(
                          plan.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                  if (unassigned.length > 2)
                    Text(
                      AppStrings.attentionMore(unassigned.length - 2),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static IconData _mealSlotIcon(String slot) => switch (slot) {
        MealSlots.breakfast => Icons.free_breakfast_outlined,
        MealSlots.lunch => Icons.lunch_dining_outlined,
        MealSlots.dinner => Icons.dinner_dining_outlined,
        _ => Icons.restaurant_outlined,
      };
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

class _DeviceAlertsBanner extends ConsumerWidget {
  const _DeviceAlertsBanner({required this.blockers});

  final List<AppPermissionInfo> blockers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final needsNotifications = blockers.any(
      (b) => b.kind == AppPermissionKind.notifications,
    );
    final needsExactAlarms = blockers.any(
      (b) => b.kind == AppPermissionKind.exactAlarms,
    );

    final hints = <String>[
      if (needsNotifications) AppStrings.deviceAlertsNotificationsHint,
      if (needsExactAlarms) AppStrings.deviceAlertsExactAlarmHint,
    ];

    return Card(
      color: theme.colorScheme.errorContainer.withOpacity(0.35),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.deviceAlertsDisabled,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...hints.map(
                    (hint) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        hint,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DevicePermissionsScreen(),
                  ),
                );
                ref.invalidate(deviceReminderBlockersProvider);
              },
              child: const Text(AppStrings.deviceAlertsFix),
            ),
          ],
        ),
      ),
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

class _DashboardDeviceBlockersBanner extends ConsumerWidget {
  const _DashboardDeviceBlockersBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockersAsync = ref.watch(deviceReminderBlockersProvider);
    return blockersAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (blockers) {
        if (blockers.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _DeviceAlertsBanner(blockers: blockers),
        );
      },
    );
  }
}

class _DashboardSetupChecklist extends ConsumerWidget {
  const _DashboardSetupChecklist();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dismissedAsync = ref.watch(setupChecklistDismissedProvider);
    return dismissedAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (dismissed) {
        if (dismissed) return const SizedBox.shrink();
        return const _DashboardSetupChecklistLoaded();
      },
    );
  }
}

class _DashboardSetupChecklistLoaded extends ConsumerWidget {
  const _DashboardSetupChecklistLoaded();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checklistAsync = ref.watch(setupChecklistProvider);
    return checklistAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (checklist) {
        if (checklist == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SetupChecklistCard(checklist: checklist),
        );
      },
    );
  }
}

class _DashboardExpensesSummary extends ConsumerWidget {
  const _DashboardExpensesSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(expenseSummaryProvider);
    return summaryAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: LinearProgressIndicator(),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (rows) {
        final total = rows.fold<double>(0.0, (s, r) => s + r.totalAmount);
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
    );
  }
}

class _DashboardMedicineToday extends ConsumerWidget {
  const _DashboardMedicineToday();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicineTodayAsync = ref.watch(medicineRemindersTodayProvider);
    final medicineTakenAsync = ref.watch(medicineDosesTakenTodayProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final roster = ref.watch(familyRosterProvider).valueOrNull ?? const [];
    final selfMemberId = currentUserId == null
        ? null
        : roster
            .where((m) => m.userId == currentUserId)
            .map((m) => m.id)
            .cast<String?>()
            .firstWhere((_) => true, orElse: () => null);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: medicineTodayAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (reminders) {
          if (reminders.isEmpty) return const SizedBox.shrink();
          final takenKeys = medicineTakenAsync.valueOrNull ?? {};
          final pending = reminders
              .where(
                (item) => !takenKeys.contains(
                  MedicineDoseTracker.doseKey(
                    item.scheduleId,
                    item.timeIndex,
                  ),
                ),
              )
              .toList();
          final takenCount = reminders.length - pending.length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MedicineTodayCard(
              reminders: reminders,
              takenKeys: takenKeys,
              pendingCount: pending.length,
              takenCount: takenCount,
              selfMemberId: selfMemberId,
            ),
          );
        },
      ),
    );
  }
}

class _DashboardTodayMeals extends ConsumerWidget {
  const _DashboardTodayMeals();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsAsync = ref.watch(todayMealPlansProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: mealsAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (meals) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _TodayEatPlanCard(meals: meals),
        ),
      ),
    );
  }
}

class _DashboardOpenPlans extends ConsumerWidget {
  const _DashboardOpenPlans();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(openPlansOverviewProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: overviewAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (overview) {
          final plans = overview.preview;
          return _TodayCard(
            icon: Icons.event_note_outlined,
            title: AppStrings.openPlans,
            subtitle: overview.totalCount == 0
                ? AppStrings.noOpenPlans
                : '${overview.totalCount} open',
            onTap: () => context.go('/plans'),
            moreCount: overview.totalCount > 3 ? overview.totalCount - 3 : 0,
            emptyText: AppStrings.noOpenPlans,
            children: plans.take(3).map((plan) {
              return _TodayRow(
                title: plan.title,
                subtitle: [
                  PlanTypes.labelFor(plan.planType),
                  if (plan.dueAt != null) Formatters.dateTime(plan.dueAt!),
                ].join(' · '),
                icon: DashboardScreen._planIcon(plan.planType),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
