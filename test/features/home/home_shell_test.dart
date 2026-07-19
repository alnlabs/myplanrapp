import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/home/presentation/home_shell.dart';

void main() {
  group('HomeShell widget', () {
    GoRouter buildRouter() {
      return GoRouter(
        initialLocation: '/home',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, __, shell) => HomeShell(navigationShell: shell),
            branches: [
              _branch('/home', 'Home body'),
              _branch('/pantry', 'Pantry body'),
              _branch('/plans', 'Plans body'),
              _branch('/family', 'Family body'),
            ],
          ),
        ],
      );
    }

    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: buildRouter()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('builds the fixed bottom tabs', (tester) async {
      await pump(tester);

      expect(find.text(AppStrings.navDashboard), findsOneWidget);
      expect(find.text(AppStrings.navInventory), findsOneWidget);
      expect(find.text(AppStrings.navPlans), findsOneWidget);
      expect(find.text(AppStrings.navHome), findsOneWidget);
      expect(find.text('Home body'), findsOneWidget);
    });

    testWidgets('switches branches when a tab is tapped', (tester) async {
      await pump(tester);

      await tester.tap(find.text(AppStrings.navPlans));
      await tester.pumpAndSettle();

      expect(find.text('Plans body'), findsOneWidget);
    });

    testWidgets('does not show a FAB in the shell', (tester) async {
      await pump(tester);

      expect(find.byType(FloatingActionButton), findsNothing);
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
