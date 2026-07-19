import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/auth/data/auth_repository.dart';
import 'package:myplanr/features/household/data/family_repository.dart';
import 'package:myplanr/features/household/data/household_repository.dart';
import 'package:myplanr/features/household/presentation/setup_wizard_screen.dart';
import 'package:myplanr/features/profile/presentation/profile_screen.dart';
import 'package:myplanr/shared/models/family_member.dart';

import '../../helpers/provider_overrides.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/stub_repositories.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('SetupWizardScreen behavior', () {
    late StubFamilyRepository familyRepo;
    late StubAuthRepository authRepo;

    Future<void> pumpWizard(WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/wizard',
        routes: [
          GoRoute(
            path: '/wizard',
            builder: (context, state) =>
                const SetupWizardScreen(householdId: testHouseholdId),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) =>
                const Scaffold(body: Text('home-route')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...testAuthOverrides,
            authRepositoryProvider.overrideWith((ref) => authRepo),
            familyRepositoryProvider.overrideWithValue(familyRepo),
            familyRosterProvider.overrideWith((ref) async => const [
                  FamilyMember(
                    id: 'member-1',
                    householdId: testHouseholdId,
                    displayName: 'Alex',
                    relationship: 'self',
                    memberType: 'app',
                    userId: testUserId,
                    profileDisplayName: 'Alex Parent',
                  ),
                ]),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
    }

    setUp(() {
      familyRepo = StubFamilyRepository();
      authRepo = StubAuthRepository();
    });

    testWidgets('renders first wizard step', (tester) async {
      await pumpWizard(tester);

      expect(find.text(AppStrings.setupWizardTitle), findsOneWidget);
      expect(find.text(AppStrings.wizardProfileTitle), findsOneWidget);
    });

    testWidgets('profile step validates required display name', (tester) async {
      await pumpWizard(tester);

      await tester.enterText(find.byType(TextFormField).first, '');
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.next));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.requiredField), findsOneWidget);
    });

    testWidgets('finishing wizard adds family member and navigates home',
        (tester) async {
      await pumpWizard(tester);

      await enterTextByLabel(tester, AppStrings.displayName, 'Alex Parent');
      await enterTextByLabel(tester, AppStrings.phoneOptional, '9876543210');
      await tester.tap(find.text(AppStrings.next));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.skipForNow));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.wizardFamilyTitle), findsOneWidget);
      await enterTextByLabel(tester, AppStrings.displayName, 'Sam');
      await tester.tap(find.text(AppStrings.wizardFinish));
      await tester.pumpAndSettle();

      expect(familyRepo.lastAddedMemberName, 'Sam');
      expect(find.text('home-route'), findsOneWidget);
    });
  });

  group('ProfileScreen widget', () {
    testWidgets('delegates to family member detail when linked', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          ...testAuthOverrides,
          currentUserFamilyMemberProvider
              .overrideWith((ref) async => testFamilyMembers.first),
          familyMemberProvider('member-1')
              .overrideWith((ref) async => testFamilyMembers.first),
          familyMemberDetailsProvider('member-1')
              .overrideWith((ref) async => testFamilyMemberDetails),
          householdMembersProvider.overrideWith((ref) async => []),
          activeHouseholdProvider.overrideWith((ref) async => testHousehold),
        ],
        child: const ProfileScreen(),
      );

      expect(find.text(AppStrings.profileTitle), findsOneWidget);
      expect(find.text(AppStrings.editProfile), findsWidgets);
    });
  });
}
