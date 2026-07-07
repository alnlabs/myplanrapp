import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/expenses/presentation/expenses_screen.dart';
import '../../features/home/presentation/dashboard_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/home/presentation/more_screen.dart';
import '../../features/household/presentation/household_setup_screen.dart';
import '../../features/household/presentation/setup_wizard_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/providers/onboarding_provider.dart';
import '../../features/pantry/presentation/pantry_item_form_screen.dart';
import '../../features/inventory/presentation/inventory_screen.dart';
import '../../features/plans/presentation/plan_form_screen.dart';
import '../../features/plans/presentation/plans_screen.dart';
import '../../features/recipes/presentation/recipes_screen.dart';
import '../../features/shopping/presentation/shopping_screen.dart';
import '../../features/subscriptions/presentation/subscription_form_screen.dart';
import '../../features/subscriptions/presentation/subscriptions_screen.dart';
import '../providers/supabase_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final onboardingAsync = ref.watch(onboardingCompletedProvider);

  return GoRouter(
    initialLocation: '/onboarding',
    redirect: (context, state) {
      final onboardingDone = onboardingAsync.valueOrNull ?? false;
      final session = authState.valueOrNull?.session;
      final path = state.matchedLocation;
      final isAuthRoute =
          path == '/login' || path == '/register' || path == '/forgot-password';
      final isOnboarding = path == '/onboarding';

      if (!onboardingDone && !isOnboarding) return '/onboarding';
      if (onboardingDone && isOnboarding) {
        return session != null ? '/home' : '/login';
      }
      if (session == null && !isAuthRoute && !isOnboarding) return '/login';
      if (session != null && isAuthRoute) return '/home';
      if (session != null &&
          path != '/household-setup' &&
          !path.startsWith('/home') &&
          !path.startsWith('/pantry') &&
          !path.startsWith('/recipes') &&
          !path.startsWith('/more') &&
          !path.startsWith('/plans') &&
          !path.startsWith('/subscriptions') &&
          !path.startsWith('/setup-wizard') &&
          path != '/pantry/add') {
        final profile = ref.read(userProfileProvider).valueOrNull;
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
        builder: (_, __) => const PlanFormScreen(),
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
      GoRoute(path: '/expenses', redirect: (_, __) => '/more/expenses'),
      GoRoute(path: '/shop', redirect: (_, __) => '/more/shop'),
      GoRoute(path: '/subscriptions', redirect: (_, __) => '/more/subscriptions'),
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
                builder: (_, __) => const InventoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/plans',
                builder: (_, __) => const PlansScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/recipes',
                builder: (_, __) => const RecipesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (_, __) => const MoreScreen(),
                routes: [
                  GoRoute(
                    path: 'expenses',
                    builder: (_, __) => const ExpensesScreen(),
                  ),
                  GoRoute(
                    path: 'shop',
                    builder: (_, __) => const ShoppingScreen(),
                  ),
                  GoRoute(
                    path: 'subscriptions',
                    builder: (_, __) => const SubscriptionsScreen(),
                  ),
                ],
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
