import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/auth/data/auth_repository.dart';
import 'package:myplanr/features/auth/presentation/account_restore_screen.dart';
import 'package:myplanr/features/auth/presentation/forgot_password_screen.dart';
import 'package:myplanr/features/auth/presentation/login_screen.dart';
import 'package:myplanr/features/auth/presentation/register_screen.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/provider_overrides.dart';
import '../../helpers/stub_repositories.dart';
import 'package:myplanr/shared/models/user_profile.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('LoginScreen', () {
    testWidgets('renders sign-in form', (tester) async {
      await pumpShellTestApp(
        tester,
        overrides: [
          authRepositoryProvider.overrideWith(
            (ref) => StubAuthRepository(profile: testUserProfile),
          ),
        ],
        child: const LoginScreen(),
      );

      expect(find.text(AppStrings.signIn), findsWidgets);
      expect(find.text(AppStrings.emailOrUsername), findsOneWidget);
      expect(find.text(AppStrings.forgotPassword), findsOneWidget);
      expect(find.text(AppStrings.signUp), findsOneWidget);
    });

    testWidgets('shows validation for empty submit', (tester) async {
      await pumpShellTestApp(
        tester,
        child: const LoginScreen(),
      );

      await tapLabeledButton(tester, AppStrings.signIn);
      expect(find.text(AppStrings.requiredField), findsWidgets);
    });
  });

  group('RegisterScreen', () {
    testWidgets('renders registration form', (tester) async {
      await pumpShellTestApp(
        tester,
        child: const RegisterScreen(),
      );

      expect(find.text(AppStrings.signUp), findsWidgets);
      expect(find.text(AppStrings.displayName), findsOneWidget);
      expect(find.text(AppStrings.email), findsOneWidget);
    });

    testWidgets('requires terms acceptance', (tester) async {
      await pumpShellTestApp(
        tester,
        child: const RegisterScreen(),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'Alex');
      await tester.enterText(find.byType(TextFormField).at(1), 'alexuser');
      await tester.enterText(find.byType(TextFormField).at(2), 'alex@example.com');
      await tester.enterText(find.byType(TextFormField).at(3), 'secret1');
      await tester.enterText(find.byType(TextFormField).at(4), 'secret1');
      await tapLabeledButton(tester, AppStrings.signUp);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.termsRequired), findsOneWidget);
    });
  });

  group('ForgotPasswordScreen', () {
    testWidgets('renders reset form', (tester) async {
      await pumpShellTestApp(
        tester,
        child: const ForgotPasswordScreen(),
      );

      expect(find.text(AppStrings.resetPassword), findsWidgets);
      expect(find.text(AppStrings.email), findsOneWidget);
    });
  });

  group('AccountRestoreScreen', () {
    testWidgets('renders restore actions for pending deletion', (tester) async {
      await pumpShellTestApp(
        tester,
        overrides: [
          userProfileProvider.overrideWith(
            (ref) async => UserProfile(
              id: testUserId,
              displayName: 'Test User',
              activeHouseholdId: testHouseholdId,
              deletedAt: DateTime(2026, 7, 1),
            ),
          ),
          authRepositoryProvider.overrideWith((ref) => StubAuthRepository()),
        ],
        child: const AccountRestoreScreen(),
      );

      expect(find.text(AppStrings.accountRestoreTitle), findsWidgets);
      expect(find.text(AppStrings.accountRestoreKeep), findsOneWidget);
      expect(find.text(AppStrings.signOut), findsOneWidget);
    });
  });
}
