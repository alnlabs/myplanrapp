import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/models/household.dart';

void main() {
  group('Household.fromJson', () {
    test('parses household fields', () {
      final household = Household.fromJson({
        'id': 'hh-1',
        'name': 'Kumar Family',
        'owner_id': 'u1',
      });
      expect(household.name, 'Kumar Family');
      expect(household.ownerId, 'u1');
    });
  });

  group('HouseholdMember', () {
    test('listLabel uses display name', () {
      const member = HouseholdMember(
        id: 'm1',
        userId: 'u1',
        role: 'owner',
        displayName: 'Alex Kumar',
        username: 'alex',
      );
      expect(member.listLabel, 'Alex Kumar');
    });

    test('fromJson reads nested profile', () {
      final member = HouseholdMember.fromJson({
        'id': 'm1',
        'user_id': 'u1',
        'role': 'member',
        'profiles': {
          'display_name': 'Sam',
          'username': 'samuser',
        },
      });
      expect(member.displayName, 'Sam');
      expect(member.username, 'samuser');
    });
  });
}
