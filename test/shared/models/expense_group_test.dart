import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/models/expense_group.dart';

void main() {
  group('ExpenseGroup', () {
    test('isShared when group_type is shared', () {
      const group = ExpenseGroup(
        id: 'g1',
        householdId: 'hh',
        name: 'Trip',
        groupType: 'shared',
      );
      expect(group.isShared, isTrue);
    });

    test('isShared is false for organizational groups', () {
      const group = ExpenseGroup(
        id: 'g2',
        householdId: 'hh',
        name: 'Household',
        groupType: 'organizational',
      );
      expect(group.isShared, isFalse);
    });

    test('fromJson counts embedded members', () {
      final group = ExpenseGroup.fromJson({
        'id': 'g1',
        'household_id': 'hh',
        'name': 'Trip',
        'group_type': 'shared',
        'created_by': 'user-1',
        'expense_group_members': [
          {'id': 'm1'},
          {'id': 'm2'},
          {'id': 'm3'},
        ],
      });
      expect(group.id, 'g1');
      expect(group.name, 'Trip');
      expect(group.groupType, 'shared');
      expect(group.createdBy, 'user-1');
      expect(group.memberCount, 3);
    });

    test('fromJson leaves memberCount null without embedded list', () {
      final group = ExpenseGroup.fromJson({
        'id': 'g1',
        'household_id': 'hh',
        'name': 'Trip',
        'group_type': 'shared',
      });
      expect(group.memberCount, isNull);
    });
  });

  group('ExpenseGroupMember', () {
    test('isPending when invite_status is pending', () {
      const member = ExpenseGroupMember(
        id: 'm1',
        groupId: 'g1',
        displayName: 'Guest',
        inviteStatus: 'pending',
      );
      expect(member.isPending, isTrue);
    });

    test('isPending is false for active members', () {
      const member = ExpenseGroupMember(
        id: 'm1',
        groupId: 'g1',
        displayName: 'Alex',
      );
      expect(member.isPending, isFalse);
    });

    test('fromJson reads all fields with defaults', () {
      final member = ExpenseGroupMember.fromJson({
        'id': 'm1',
        'group_id': 'g1',
        'display_name': 'Alex',
        'user_id': 'u1',
        'family_member_id': 'fm1',
        'guest_email': 'guest@example.com',
      });
      expect(member.displayName, 'Alex');
      expect(member.userId, 'u1');
      expect(member.familyMemberId, 'fm1');
      expect(member.guestEmail, 'guest@example.com');
      expect(member.inviteStatus, 'active');
      expect(member.isPending, isFalse);
    });

    test('fromJson reads pending invite_status', () {
      final member = ExpenseGroupMember.fromJson({
        'id': 'm2',
        'group_id': 'g1',
        'display_name': 'Guest',
        'invite_status': 'pending',
      });
      expect(member.isPending, isTrue);
    });
  });

  group('ExpenseGroupBalance.fromJson', () {
    test('parses balance fields', () {
      final balance = ExpenseGroupBalance.fromJson({
        'group_member_id': 'm1',
        'display_name': 'Alex',
        'paid_total': 200,
        'owed_total': 150,
        'settled_in': 20,
        'settled_out': 10,
        'net_balance': 60,
      });
      expect(balance.groupMemberId, 'm1');
      expect(balance.displayName, 'Alex');
      expect(balance.paidTotal, 200);
      expect(balance.owedTotal, 150);
      expect(balance.settledIn, 20);
      expect(balance.settledOut, 10);
      expect(balance.netBalance, 60);
    });
  });

  group('SuggestedSettlement', () {
    test('holds settlement transfer details', () {
      const settlement = SuggestedSettlement(
        fromMemberId: 'm1',
        fromName: 'Bob',
        toMemberId: 'm2',
        toName: 'Alice',
        amount: 25.5,
      );
      expect(settlement.fromMemberId, 'm1');
      expect(settlement.fromName, 'Bob');
      expect(settlement.toMemberId, 'm2');
      expect(settlement.toName, 'Alice');
      expect(settlement.amount, 25.5);
    });
  });
}
