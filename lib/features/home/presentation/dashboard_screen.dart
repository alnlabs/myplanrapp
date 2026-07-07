import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/utils/formatters.dart';
import '../../alerts/presentation/alerts_screen.dart';
import '../../expenses/data/expense_repository.dart';
import '../../expenses/presentation/add_expense_screen.dart';
import '../../household/data/household_repository.dart';
import '../../household/presentation/household_screen.dart';
import '../../pantry/data/pantry_repository.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../recipes/presentation/recipe_form_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdAsync = ref.watch(activeHouseholdProvider);
    final lowStockAsync = ref.watch(lowStockItemsProvider);
    final expiringAsync = ref.watch(expiringItemsProvider);
    final summaryAsync = ref.watch(expenseSummaryProvider);

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
                    onTap: () => context.go('/expenses'),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
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
            const SizedBox(height: 16),
            Text(AppStrings.quickActions, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text(AppStrings.addItem),
                  onPressed: () => context.push('/pantry/add'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.payments_outlined, size: 18),
                  label: const Text(AppStrings.addExpense),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const AddExpenseScreen()),
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.menu_book_outlined, size: 18),
                  label: const Text(AppStrings.addRecipe),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const RecipeFormScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
