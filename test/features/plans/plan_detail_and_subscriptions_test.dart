import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/plans/data/plan_repository.dart';
import 'package:myplanr/features/plans/presentation/plan_detail_screen.dart';
import 'package:myplanr/features/subscriptions/data/subscription_repository.dart';
import 'package:myplanr/features/subscriptions/presentation/subscriptions_screen.dart';

import '../../helpers/provider_overrides.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('PlanDetailScreen widget', () {
    testWidgets('renders plan details', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          ...testAuthOverrides,
          planProvider('plan-1').overrideWith((ref) async => testPlan),
        ],
        child: const PlanDetailScreen(planId: 'plan-1'),
      );

      expect(find.text('Buy groceries'), findsWidgets);
      expect(find.text('Task'), findsOneWidget);
    });
  });

  group('SubscriptionsScreen widget', () {
    testWidgets('renders subscriptions list', (tester) async {
      await pumpShellTestApp(
        tester,
        overrides: [
          subscriptionsProvider.overrideWith((ref) async => [testSubscription]),
          subscriptionsDueSoonProvider.overrideWith((ref) async => []),
        ],
        child: const SubscriptionsScreen(),
      );

      expect(find.text(AppStrings.subscriptionsTitle), findsOneWidget);
      expect(find.text('Netflix'), findsOneWidget);
    });

    testWidgets('shows empty state when no subscriptions', (tester) async {
      await pumpShellTestApp(
        tester,
        overrides: [
          subscriptionsProvider.overrideWith((ref) async => []),
          subscriptionsDueSoonProvider.overrideWith((ref) async => []),
        ],
        child: const SubscriptionsScreen(),
      );

      expect(find.text(AppStrings.emptySubscriptions), findsOneWidget);
    });
  });
}
