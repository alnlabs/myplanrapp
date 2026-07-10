import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/home/presentation/home_shell.dart';
import 'package:myplanr/features/household/data/household_settings_repository.dart';
import 'package:myplanr/shared/constants/household_modules.dart';

void main() {
  group('HomeShell widget', () {
    testWidgets('builds bottom nav for enabled modules', (tester) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, __, shell) => HomeShell(navigationShell: shell),
            branches: [
              _branch('/home', 'Home body'),
              _branch('/pantry', 'Pantry body'),
              _branch('/plans', 'Plans body'),
              _branch('/expenses', 'Expenses body'),
              _branch('/subscriptions', 'Subscriptions body'),
              _branch('/shop', 'Shop body'),
              _branch('/more', 'More body'),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            enabledModulesProvider.overrideWith(
              (ref) => {
                HouseholdModules.pantry,
                HouseholdModules.expenses,
              },
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.navHome), findsOneWidget);
      expect(find.text(AppStrings.navInventory), findsOneWidget);
      expect(find.text(AppStrings.navExpenses), findsOneWidget);
      expect(find.text('Home body'), findsOneWidget);
    });

    testWidgets('switches branches when destination tapped', (tester) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, __, shell) => HomeShell(navigationShell: shell),
            branches: [
              _branch('/home', 'Home body'),
              _branch('/pantry', 'Pantry body'),
              _branch('/plans', 'Plans body'),
              _branch('/expenses', 'Expenses body'),
              _branch('/subscriptions', 'Subscriptions body'),
              _branch('/shop', 'Shop body'),
              _branch('/more', 'More body'),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            enabledModulesProvider.overrideWith(
              (ref) => {
                HouseholdModules.pantry,
                HouseholdModules.expenses,
              },
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.navExpenses));
      await tester.pumpAndSettle();

      expect(find.text('Expenses body'), findsOneWidget);
    });

    testWidgets('shows More tab when many modules enabled', (tester) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, __, shell) => HomeShell(navigationShell: shell),
            branches: [
              _branch('/home', 'Home body'),
              _branch('/pantry', 'Pantry body'),
              _branch('/plans', 'Plans body'),
              _branch('/expenses', 'Expenses body'),
              _branch('/subscriptions', 'Subscriptions body'),
              _branch('/shop', 'Shop body'),
              _branch('/more', 'More body'),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            enabledModulesProvider.overrideWith(
              (ref) => HouseholdModules.defaultEnabled.toSet()
                ..add(HouseholdModules.subscriptions),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.navMore), findsOneWidget);
    });
  });
}

StatefulShellBranch _branch(String path, String label) {
  return StatefulShellBranch(
    routes: [
      GoRoute(
        path: path,
        builder: (_, __) => Scaffold(body: Center(child: Text(label))),
      ),
    ],
  );
}
