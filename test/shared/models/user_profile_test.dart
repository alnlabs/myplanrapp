import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/models/account_deletion_status.dart';
import 'package:myplanr/shared/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('hasHousehold when activeHouseholdId set', () {
      const profile = UserProfile(
        id: 'u1',
        activeHouseholdId: 'hh-1',
      );
      expect(profile.hasHousehold, isTrue);
    });

    test('deletionStatus delegates to AccountDeletionStatus', () {
      final deletedAt = DateTime.now().subtract(const Duration(days: 2));
      final profile = UserProfile(id: 'u1', deletedAt: deletedAt);
      expect(profile.isPendingDeletion, isTrue);
      expect(profile.deletionPurgeAt, isNotNull);
    });

    test('fromJson parses fields', () {
      final profile = UserProfile.fromJson({
        'id': 'u1',
        'display_name': 'Alex',
        'username': 'alex',
        'active_household_id': 'hh',
        'deleted_at': '2026-01-01T00:00:00Z',
      });
      expect(profile.displayName, 'Alex');
      expect(profile.deletedAt, isNotNull);
    });

    test('active profile has active deletion status', () {
      const profile = UserProfile(id: 'u1');
      expect(profile.deletionStatus.isActive, isTrue);
    });
  });
}
