import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/utils/member_display_name.dart';

void main() {
  group('memberListLabel', () {
    test('prefers profile display name over roster name', () {
      expect(
        memberListLabel(
          profileDisplayName: 'Alex Kumar',
          rosterDisplayName: 'Alex',
          username: 'alex',
        ),
        'Alex Kumar',
      );
    });

    test('skips name that equals username', () {
      expect(
        memberListLabel(
          profileDisplayName: 'alex',
          rosterDisplayName: 'Alex Member',
          username: 'alex',
        ),
        'Alex Member',
      );
    });

    test('falls back to username when names match username', () {
      expect(
        memberListLabel(
          rosterDisplayName: 'alexuser',
          username: 'alexuser',
        ),
        'alexuser',
      );
    });

    test('falls back to email', () {
      expect(
        memberListLabel(email: 'member@example.com'),
        'member@example.com',
      );
    });

    test('returns fallback when nothing else available', () {
      expect(memberListLabel(), 'Member');
      expect(memberListLabel(fallback: 'Guest'), 'Guest');
    });
  });
}
