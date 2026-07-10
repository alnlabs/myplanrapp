import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/account_restore_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/expenses/presentation/add_recurring_expense_screen.dart';
import '../../features/expenses/presentation/expense_group_detail_screen.dart';
import '../../features/expenses/presentation/expense_group_form_screen.dart';
import '../../features/expenses/presentation/expense_groups_screen.dart';
import '../../features/expenses/presentation/expense_settlement_screen.dart';
import '../../features/expenses/presentation/expenses_screen.dart';
import '../../features/expenses/presentation/recurring_expenses_screen.dart';
import '../../features/home/presentation/dashboard_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/home/presentation/more_screen.dart';
import '../../features/household/presentation/household_setup_screen.dart';
import '../../features/household/presentation/setup_wizard_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/providers/onboarding_provider.dart';
import '../../features/pantry/presentation/pantry_item_form_screen.dart';
import '../../features/inventory/presentation/inventory_screen.dart';
import '../../features/plans/data/todo_reminders_filter.dart';
import '../../features/plans/presentation/plan_form_screen.dart';
import '../../features/plans/presentation/plans_screen.dart';
import '../../features/reminders/presentation/reminder_form_screen.dart';
import '../../features/shopping/presentation/shopping_screen.dart';
import '../../features/subscriptions/presentation/subscription_form_screen.dart';
import '../../features/subscriptions/presentation/subscriptions_screen.dart';
import '../providers/supabase_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final onboardingAsync = ref.watch(onboardingCompletedProvider);
  final profileAsync = ref.watch(userProfileProvider);

  return GoRouter(
    initialLocation: '/onboarding',
    redirect: (context, state) {
      final onboardingDone = onboardingAsync.valueOrNull ?? false;
      final session = authState.valueOrNull?.session;
      final path = state.matchedLocation;

      // Reminders merged into the To-do tab.
      if (path == '/reminders') {
        final filter = state.uri.queryParameters['filter'] ?? 'reminders';
        return '/plans?filter=$filter';
      }

      final isOnboarding = path == '/onboarding';
      final isAuthRoute =
          path == '/login' ||
          path == '/register' ||
          path == '/forgot-password';
      final isHouseholdSetup =
          path == '/household-setup' || path.startsWith('/setup-wizard');
      final isAccountRestore = path == '/account-restore';

      // On the onboarding screen, only leave once it's been completed.
      // We never force other routes back to onboarding (avoids redirect
      // loops when the completion flag is mid-write).
      if (isOnboarding) {
        if (!onboardingDone) return null;
        if (session == null) return '/login';
        final profile = profileAsync.valueOrNull;
        if (profile?.isPendingDeletion == true) return '/account-restore';
        if (profile != null && !profile.hasHousehold) {
          return '/household-setup';
        }
        return '/home';
      }

      // Not signed in: only auth/legal routes are reachable.
      if (session == null) {
        return isAuthRoute ? null : '/login';
      }

      final profile = profileAsync.valueOrNull;

      // Soft-deleted account still within grace period: must restore or sign out.
      if (profile?.isPendingDeletion == true && !isAccountRestore) {
        return '/account-restore';
      }

      // Signed in but sitting on an auth route: move into the app.
      if (isAuthRoute) {
        if (profile != null && !profile.hasHousehold) {
          return '/household-setup';
        }
        return '/home';
      }

      // Signed in with no family: force family creation first.
      if (!isHouseholdSetup && !isAccountRestore) {
        if (profile != null && !profile.hasHousehold) {
          return '/household-setup';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/account-restore',
        builder: (_, __) => const AccountRestoreScreen(),
      ),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/household-setup',
        builder: (_, __) => const HouseholdSetupScreen(),
      ),
      GoRoute(
        path: '/pantry/add',
        builder: (_, __) => const PantryItemFormScreen(),
      ),
      GoRoute(
        path: '/plans/add',
        builder: (context, state) {
          final type = state.uri.queryParameters['type'];
          final slot = state.uri.queryParameters['slot'];
          return PlanFormScreen(
            initialPlanType: type,
            initialMealSlot: slot,
          );
        },
      ),
      GoRoute(
        path: '/setup-wizard',
        builder: (context, state) {
          final householdId = state.uri.queryParameters['householdId'] ?? '';
          return SetupWizardScreen(householdId: householdId);
        },
      ),
      GoRoute(
        path: '/subscriptions/add',
        builder: (_, __) => const SubscriptionFormScreen(),
      ),
      GoRoute(
        path: '/subscriptions/edit',
        builder: (context, state) {
          final id = state.uri.queryParameters['id'] ?? '';
          return SubscriptionFormScreen(subscriptionId: id);
        },
      ),
      GoRoute(
        path: '/reminders/add',
        builder: (_, __) => const ReminderFormScreen(),
      ),
      GoRoute(
        path: '/reminders/edit',
        builder: (context, state) {
          final id = state.uri.queryParameters['id'] ?? '';
          return ReminderFormScreen(standaloneId: id);
        },
      ),
      GoRoute(
        path: '/expenses/groups',
        builder: (_, __) => const ExpenseGroupsScreen(),
      ),
      GoRoute(
        path: '/expenses/groups/add',
        builder: (_, __) => const ExpenseGroupFormScreen(),
      ),
      GoRoute(
        path: '/expenses/groups/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ExpenseGroupDetailScreen(groupId: id);
        },
      ),
      GoRoute(
        path: '/expenses/groups/:id/settle',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ExpenseSettlementScreen(groupId: id);
        },
      ),
      GoRoute(
        path: '/expenses/recurring',
        builder: (_, __) => const RecurringExpensesScreen(),
      ),
      GoRoute(
        path: '/expenses/recurring/add',
        builder: (_, __) => const AddRecurringExpenseScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/pantry',
                builder: (context, state) {
                  final segment = state.uri.queryParameters['segment'];
                  return InventoryScreen(
                    initialSegment: segment == 'assets'
                        ? InventorySegment.assets
                        : InventorySegment.food,
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/plans',
                builder: (context, state) {
                  final filter = TodoRemindersFilter.fromQuery(
                    state.uri.queryParameters['filter'],
                  );
                  return PlansScreen(
                    initialFilter: filter ?? TodoRemindersFilter.all,
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/expenses',
                builder: (_, __) => const ExpensesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/subscriptions',
                builder: (_, __) => const SubscriptionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shop',
                builder: (_, __) => const ShoppingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (_, __) => const MoreScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

final householdGateProvider = FutureProvider<bool>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return profile?.hasHousehold ?? false;
});
