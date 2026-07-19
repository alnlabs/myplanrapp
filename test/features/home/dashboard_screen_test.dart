import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/home/presentation/dashboard_screen.dart';

import '../../helpers/dashboard_overrides.dart';

void main() {
  group('DashboardScreen behavior', () {
    Future<void> pumpDashboardWithRoutes(WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/plans/add',
            builder: (context, state) =>
                const Scaffold(body: Text('plans-add-route')),
          ),
          GoRoute(
            path: '/expenses/add',
            builder: (context, state) =>
                const Scaffold(body: Text('expenses-add-route')),
          ),
          GoRoute(
            path: '/shop',
            builder: (context, state) =>
                const Scaffold(body: Text('shop-route')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: dashboardTestOverrides(),
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders greeting', (tester) async {
      await pumpDashboardWithRoutes(tester);

      expect(
        find.textContaining(
          RegExp(
            '${AppStrings.goodMorning}|${AppStrings.goodAfternoon}|${AppStrings.goodEvening}',
          ),
        ),
        findsOneWidget,
      );
    });
  });
}
