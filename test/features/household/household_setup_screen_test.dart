import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/household/data/household_repository.dart';
import 'package:myplanr/features/household/presentation/household_setup_screen.dart';

import '../../helpers/provider_overrides.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/stub_repositories.dart';

void main() {
  group('HouseholdSetupScreen widget', () {
    testWidgets('renders create household form', (tester) async {
      await pumpShellTestApp(
        tester,
        overrides: [
          ...testAuthOverrides,
          householdRepositoryProvider.overrideWith(
            (ref) => StubHouseholdRepository(),
          ),
        ],
        child: const HouseholdSetupScreen(),
      );

      expect(find.text(AppStrings.noHousehold), findsOneWidget);
      expect(find.text(AppStrings.householdName), findsOneWidget);
      expect(find.text(AppStrings.createHousehold), findsOneWidget);
    });

    testWidgets('shows pending invites when available', (tester) async {
      await pumpShellTestApp(
        tester,
        overrides: [
          ...testAuthOverrides,
          householdRepositoryProvider.overrideWith(
            (ref) => StubHouseholdRepository(
              pendingInvites: [
                {
                  'household_id': 'hh-invite-1',
                  'households': {'name': 'Smith Family'},
                },
              ],
            ),
          ),
        ],
        child: const HouseholdSetupScreen(),
      );

      expect(find.text(AppStrings.joinHousehold), findsOneWidget);
      expect(find.text('Smith Family'), findsOneWidget);
    });

    testWidgets('validates household name before create', (tester) async {
      await pumpShellTestApp(
        tester,
        overrides: [
          ...testAuthOverrides,
          householdRepositoryProvider.overrideWith(
            (ref) => StubHouseholdRepository(),
          ),
        ],
        child: const HouseholdSetupScreen(),
      );

      await tapLabeledButton(tester, AppStrings.createHousehold);
      expect(find.text(AppStrings.requiredField), findsOneWidget);
    });

    testWidgets('creates household and navigates to setup wizard', (tester) async {
      String? navigatedTo;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const HouseholdSetupScreen(),
          ),
          GoRoute(
            path: '/setup-wizard',
            builder: (_, state) {
              navigatedTo = state.uri.toString();
              return const Scaffold(body: Text('Wizard'));
            },
          ),
        ],
      );

      final stubRepo = StubHouseholdRepository(createdHouseholdId: 'hh-created');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...testAuthOverrides,
            householdRepositoryProvider.overrideWith((ref) => stubRepo),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await enterTextByLabel(tester, AppStrings.householdName, 'New Family');
      await tapLabeledButton(tester, AppStrings.createHousehold);
      await tester.pumpAndSettle();

      expect(stubRepo.lastCreatedName, 'New Family');
      expect(navigatedTo, '/setup-wizard?householdId=hh-created');
      expect(find.text('Wizard'), findsOneWidget);
    });
  });
}
