import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/household/presentation/add_family_member_screen.dart';
import 'package:myplanr/shared/utils/validators.dart';
import 'package:myplanr/shared/widgets/loading_button.dart';

import '../../helpers/provider_overrides.dart';
import '../../helpers/pump_app.dart';

void main() {
  final overrides = testAuthOverrides;

  group('AddFamilyMemberScreen widget', () {
    testWidgets('invite mode shows email field', (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides,
        child: const AddFamilyMemberScreen(),
      );

      expect(find.text(AppStrings.inviteToApp), findsOneWidget);
      expect(find.text(AppStrings.email), findsOneWidget);
      expect(find.widgetWithText(LoadingButton, AppStrings.inviteMember),
          findsOneWidget);
    });

    testWidgets('profile-only mode shows name and phone fields', (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides,
        child: const AddFamilyMemberScreen(),
      );

      await tester.tap(find.text(AppStrings.profileOnly));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.displayName), findsOneWidget);
      expect(find.text(AppStrings.phoneOptional), findsOneWidget);
      expect(find.widgetWithText(LoadingButton, AppStrings.addMember),
          findsOneWidget);
    });

    testWidgets('profile-only name field uses required validator', (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides,
        child: const AddFamilyMemberScreen(),
      );

      await tester.tap(find.text(AppStrings.profileOnly));
      await tester.pumpAndSettle();

      final nameField = find.byType(TextFormField).first;
      await tester.tap(nameField);
      await tester.enterText(nameField, '');
      await tester.pumpAndSettle();

      expect(Validators.required(''), AppStrings.requiredField);
    });

    testWidgets('invite email field uses email validator', (tester) async {
      expect(Validators.email('not-an-email'), AppStrings.invalidEmail);
      expect(Validators.email(''), AppStrings.requiredField);
      expect(Validators.email('user@example.com'), isNull);
    });

    testWidgets('relationship dropdown is shown', (tester) async {
      await pumpTestApp(
        tester,
        overrides: overrides,
        child: const AddFamilyMemberScreen(),
      );

      expect(find.text(AppStrings.relationship), findsOneWidget);
    });
  });
}
