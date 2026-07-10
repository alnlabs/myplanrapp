import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/household/presentation/member_role_actions.dart';
import 'package:myplanr/features/household/presentation/member_role_helpers.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('MemberRoleActions widget', () {
    testWidgets('shows make co-owner for regular member', (tester) async {
      var promoted = false;
      await pumpTestApp(
        tester,
        child: MemberRoleActions(
          currentRole: 'member',
          onMakeCoOwner: () => promoted = true,
          onMakeMember: () {},
        ),
      );

      expect(find.text(AppStrings.makeCoOwner), findsOneWidget);
      await tester.tap(find.text(AppStrings.makeCoOwner));
      expect(promoted, isTrue);
    });

    testWidgets('shows remove co-owner for co-owner role', (tester) async {
      await pumpTestApp(
        tester,
        child: MemberRoleActions(
          currentRole: 'co_owner',
          onMakeCoOwner: () {},
          onMakeMember: () {},
        ),
      );

      expect(find.text(AppStrings.removeCoOwner), findsOneWidget);
    });
  });

  group('MemberRoleBadge widget', () {
    testWidgets('renders owner and co-owner labels', (tester) async {
      await pumpTestApp(
        tester,
        child: const Column(
          children: [
            MemberRoleBadge(role: 'owner'),
            MemberRoleBadge(role: 'co_owner'),
            MemberRoleBadge(role: 'member'),
          ],
        ),
      );

      expect(find.text(roleLabel('owner')), findsOneWidget);
      expect(find.text(roleLabel('co_owner')), findsOneWidget);
      expect(find.text(roleLabel('member')), findsOneWidget);
    });
  });
}
