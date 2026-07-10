import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/features/household/data/member_avatar_repository.dart';
import 'package:myplanr/features/household/presentation/member_avatar_circle.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('MemberAvatarCircle widget', () {
    testWidgets('shows initial when no avatar path', (tester) async {
      await pumpTestApp(
        tester,
        child: const MemberAvatarCircle(displayName: 'Alex'),
      );

      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('shows initial when avatar url is unavailable', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            memberAvatarUrlProvider('avatars/alex.png').overrideWith(
              (ref) async => null,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MemberAvatarCircle(
                displayName: 'Alex',
                avatarPath: 'avatars/alex.png',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('shows question mark for empty display name', (tester) async {
      await pumpTestApp(
        tester,
        child: const MemberAvatarCircle(displayName: ''),
      );

      expect(find.text('?'), findsOneWidget);
    });
  });
}
