import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/household/presentation/member_role_helpers.dart';
import 'package:myplanr/shared/models/household.dart';

void main() {
  group('roleLabel', () {
    test('maps known roles', () {
      expect(roleLabel('owner'), AppStrings.roleOwner);
      expect(roleLabel('co_owner'), AppStrings.roleCoOwner);
      expect(roleLabel('member'), AppStrings.roleMember);
      expect(roleLabel('unknown'), AppStrings.roleMember);
    });
  });

  group('membershipForUser', () {
    final members = [
      const HouseholdMember(
        id: 'm1',
        userId: 'u1',
        role: 'owner',
        displayName: 'Alex',
      ),
      const HouseholdMember(
        id: 'm2',
        userId: 'u2',
        role: 'member',
      ),
    ];

    test('finds member by user id', () {
      expect(membershipForUser(members, 'u2')?.role, 'member');
    });

    test('returns null for missing user', () {
      expect(membershipForUser(members, null), isNull);
      expect(membershipForUser(members, 'missing'), isNull);
    });
  });

  group('canChangeRole', () {
    test('owner can change another non-owner role', () {
      expect(
        canChangeRole(
          isOwner: true,
          targetUserId: 'u2',
          currentUserId: 'u1',
          targetRole: 'member',
        ),
        isTrue,
      );
    });

    test('cannot change own role', () {
      expect(
        canChangeRole(
          isOwner: true,
          targetUserId: 'u1',
          currentUserId: 'u1',
          targetRole: 'member',
        ),
        isFalse,
      );
    });

    test('cannot assign owner role', () {
      expect(
        canChangeRole(
          isOwner: true,
          targetUserId: 'u2',
          currentUserId: 'u1',
          targetRole: 'owner',
        ),
        isFalse,
      );
    });

    test('non-owner cannot change roles', () {
      expect(
        canChangeRole(
          isOwner: false,
          targetUserId: 'u2',
          currentUserId: 'u3',
          targetRole: 'member',
        ),
        isFalse,
      );
    });
  });
}
