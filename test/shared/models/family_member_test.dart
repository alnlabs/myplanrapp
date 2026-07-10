import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/constants/family_relationships.dart';
import 'package:myplanr/shared/models/family_member.dart';

void main() {
  group('FamilyMember', () {
    test('member type helpers', () {
      const appMember = FamilyMember(
        id: 'f1',
        householdId: 'hh',
        displayName: 'Alex',
        relationship: 'self',
        memberType: 'app',
      );
      expect(appMember.isAppMember, isTrue);
      expect(appMember.isRosterOnly, isFalse);

      const roster = FamilyMember(
        id: 'f2',
        householdId: 'hh',
        displayName: 'Kid',
        relationship: 'child',
        memberType: 'roster',
        inviteStatus: 'pending',
      );
      expect(roster.isRosterOnly, isTrue);
      expect(roster.isPendingInvite, isTrue);
    });

    test('relationshipLabel uses constants', () {
      const member = FamilyMember(
        id: 'f1',
        householdId: 'hh',
        displayName: 'Alex',
        relationship: 'spouse',
        memberType: 'app',
      );
      expect(member.relationshipLabel, FamilyRelationships.spouse.label);
    });

    test('listLabel prefers profile display name', () {
      const member = FamilyMember(
        id: 'f1',
        householdId: 'hh',
        displayName: 'Alex Roster',
        relationship: 'self',
        memberType: 'app',
        profileDisplayName: 'Alex Kumar',
        profileUsername: 'alex',
      );
      expect(member.listLabel, 'Alex Kumar');
    });

    test('fromJson parses profile and avatar list', () {
      final member = FamilyMember.fromJson({
        'id': 'f1',
        'household_id': 'hh',
        'display_name': 'Alex',
        'relationship': 'self',
        'member_type': 'app',
        'profiles': {
          'display_name': 'Alex Kumar',
          'username': 'alex',
        },
        'household_member_details': [
          {'avatar_url': 'https://example.com/a.png'},
        ],
      });
      expect(member.profileDisplayName, 'Alex Kumar');
      expect(member.avatarUrl, 'https://example.com/a.png');
    });
  });

  group('FamilyMemberDetails', () {
    test('isVisible defaults true for unknown keys', () {
      const details = FamilyMemberDetails(
        familyMemberId: 'f1',
        householdId: 'hh',
      );
      expect(details.isVisible('phone'), isTrue);
    });

    test('isVisible respects visibility map', () {
      const details = FamilyMemberDetails(
        familyMemberId: 'f1',
        householdId: 'hh',
        visibility: {'phone': false},
      );
      expect(details.isVisible('phone'), isFalse);
    });

    test('fromJson parses clothing and visibility maps', () {
      final details = FamilyMemberDetails.fromJson({
        'family_member_id': 'f1',
        'household_id': 'hh',
        'clothing_sizes': {'shirt': 'M'},
        'visibility': {'health': false},
      });
      expect(details.clothingSizes['shirt'], 'M');
      expect(details.isVisible('health'), isFalse);
    });

    test('copyWith updates fields', () {
      const original = FamilyMemberDetails(
        familyMemberId: 'f1',
        householdId: 'hh',
        phone: '111',
      );
      final updated = original.copyWith(phone: '222');
      expect(updated.phone, '222');
    });
  });
}
