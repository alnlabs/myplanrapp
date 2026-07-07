import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/household_modules.dart';
import '../../../shared/utils/formatters.dart';
import '../../alerts/presentation/alerts_screen.dart';
import '../../expenses/data/expense_repository.dart';
import '../../expenses/presentation/add_expense_screen.dart';
import '../../household/data/household_repository.dart';
import '../../household/data/household_settings_repository.dart';
import '../../assets/data/asset_repository.dart';
import '../../plans/data/plan_repository.dart';
import '../../subscriptions/data/subscription_repository.dart';
import '../../household/presentation/household_screen.dart';
import '../../pantry/data/pantry_repository.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../recipes/presentation/recipe_form_screen.dart';
import '../data/setup_checklist_provider.dart';
import 'setup_checklist_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdAsync = ref.watch(activeHouseholdProvider);
    final modules = ref.watch(enabledModulesProvider);
    final lowStockAsync = ref.watch(lowStockItemsProvider);
    final expiringAsync = ref.watch(expiringItemsProvider);
    final summaryAsync = ref.watch(expenseSummaryProvider);
    final openPlansAsync = ref.watch(openPlansProvider);
    final warrantyAsync = ref.watch(warrantyExpiringAssetsProvider);
    final subsDueSoonAsync = ref.watch(subscriptionsDueSoonProvider);
    final checklistAsync = ref.watch(setupChecklistProvider);

    final showExpenses = modules.contains(HouseholdModules.expenses);
    final showPlans = modules.contains(HouseholdModules.plans);
    final showAssets = modules.contains(HouseholdModules.assets);
    final showPantry = modules.contains(HouseholdModules.pantry);
    final showRecipes = modules.contains(HouseholdModules.recipes);
    final showSubscriptions = modules.contains(HouseholdModules.subscriptions);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.dashboardTitle),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'alerts':
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const AlertsScreen()),
                  );
                case 'family':
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const HouseholdScreen()),
                  );
                case 'profile':
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
                  );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'alerts', child: Text(AppStrings.alertsTitle)),
              PopupMenuItem(value: 'family', child: Text(AppStrings.householdTitle)),
              PopupMenuItem(value: 'profile', child: Text(AppStrings.profileTitle)),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeHouseholdProvider);
          ref.invalidate(lowStockItemsProvider);
          ref.invalidate(expiringItemsProvider);
          ref.invalidate(expenseSummaryProvider);
          ref.invalidate(openPlansProvider);
          ref.invalidate(warrantyExpiringAssetsProvider);
          ref.invalidate(subscriptionsDueSoonProvider);
          ref.invalidate(setupChecklistProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            householdAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (household) {
                if (household == null) return const SizedBox.shrink();
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.family_restroom_outlined),
                    title: Text(household.name),
                    subtitle: const Text(AppStrings.householdTitle),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            checklistAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (checklist) {
                if (checklist == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SetupChecklistCard(checklist: checklist),
                );
              },
            ),
            if (showExpenses)
              summaryAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (rows) {
                  final total = rows.fold<double>(0, (s, r) => s + r.totalAmount);
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.payments_outlined),
                      title: const Text(AppStrings.monthlyTotal),
                      subtitle: Text(Formatters.monthYear(DateTime.now())),
                      trailing: Text(
                        Formatters.currency(total),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      onTap: () => context.go('/more/expenses'),
                    ),
                  );
                },
              ),
            if (showExpenses) const SizedBox(height: 12),
            if (showPlans)
              openPlansAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (plans) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.event_note_outlined),
                    title: const Text(AppStrings.openPlans),
                    subtitle: Text(
                      plans.isEmpty
                          ? 'No open plans'
                          : '${plans.length} open plan${plans.length == 1 ? '' : 's'}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/plans'),
                  ),
                ),
              ),
            if (showPlans) const SizedBox(height: 12),
            if (showSubscriptions)
              subsDueSoonAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (subs) {
                  if (subs.isEmpty) return const SizedBox.shrink();
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.subscriptions_outlined),
                      title: const Text(AppStrings.subscriptionsDueSoon),
                      subtitle: Text(
                        subs.map((s) => s.name).take(2).join(', ') +
                            (subs.length > 2 ? '…' : ''),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/more/subscriptions'),
                    ),
                  );
                },
              ),
            if (showSubscriptions) const SizedBox(height: 12),
            if (showAssets)
              warrantyAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (assets) {
                  if (assets.isEmpty) return const SizedBox.shrink();
                  return Card(
                    child: ListTile(
                      leading: Icon(Icons.verified_outlined, color: Colors.amber.shade800),
                      title: const Text(AppStrings.warrantyExpiringTitle),
                      subtitle: Text(
                        '${assets.length} item${assets.length == 1 ? '' : 's'} — ${assets.map((a) => a.name).take(2).join(', ')}${assets.length > 2 ? '…' : ''}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/pantry'),
                    ),
                  );
                },
              ),
            if (showAssets) const SizedBox(height: 12),
            if (showPantry)
              lowStockAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (items) => Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.warning_amber_outlined,
                      color: items.isEmpty ? null : Colors.amber.shade800,
                    ),
                    title: const Text(AppStrings.alertsTitle),
                    subtitle: Text(
                      items.isEmpty
                          ? AppStrings.emptyAlerts
                          : '${items.length} item${items.length == 1 ? '' : 's'} need attention',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const AlertsScreen()),
                    ),
                  ),
                ),
              ),
            if (showPantry) const SizedBox(height: 12),
            if (showPantry)
              expiringAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (items) => Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ListTile(
                        leading: Icon(Icons.event_outlined),
                        title: Text(AppStrings.expiringSoon),
                      ),
                      if (items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(AppStrings.noExpiring),
                        )
                      else
                        ...items.map(
                          (item) => ListTile(
                            dense: true,
                            title: Text(item.name),
                            subtitle: Text(Formatters.date(item.expiryDate!)),
                            trailing: Text(Formatters.quantity(item.quantity, item.unit)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (showPantry) const SizedBox(height: 16),
            Text(AppStrings.quickActions, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (showPlans)
                  ActionChip(
                    avatar: const Icon(Icons.event_note_outlined, size: 18),
                    label: const Text(AppStrings.addPlan),
                    onPressed: () => context.push('/plans/add'),
                  ),
                if (showPantry)
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text(AppStrings.addItem),
                    onPressed: () => context.push('/pantry/add'),
                  ),
                if (showExpenses)
                  ActionChip(
                    avatar: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text(AppStrings.addExpense),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const AddExpenseScreen()),
                    ),
                  ),
                if (showRecipes)
                  ActionChip(
                    avatar: const Icon(Icons.menu_book_outlined, size: 18),
                    label: const Text(AppStrings.addRecipe),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const RecipeFormScreen()),
                    ),
                  ),
                if (showSubscriptions)
                  ActionChip(
                    avatar: const Icon(Icons.subscriptions_outlined, size: 18),
                    label: const Text(AppStrings.addSubscription),
                    onPressed: () => context.push('/subscriptions/add'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
