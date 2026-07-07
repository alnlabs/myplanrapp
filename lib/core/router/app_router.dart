import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/expenses/presentation/expenses_screen.dart';
import '../../features/home/presentation/dashboard_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/household/presentation/household_setup_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/providers/onboarding_provider.dart';
import '../../features/pantry/presentation/pantry_item_form_screen.dart';
import '../../features/pantry/presentation/pantry_screen.dart';
import '../../features/recipes/presentation/recipes_screen.dart';
import '../../features/shopping/presentation/shopping_screen.dart';
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
          !path.startsWith('/expenses') &&
          !path.startsWith('/shop') &&
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
                builder: (_, __) => const PantryScreen(),
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
                path: '/expenses',
                builder: (_, __) => const ExpensesScreen(),
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
        ],
      ),
    ],
  );
});

final householdGateProvider = FutureProvider<bool>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return profile?.hasHousehold ?? false;
});
