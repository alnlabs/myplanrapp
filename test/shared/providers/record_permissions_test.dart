import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/providers/record_permissions.dart';

void main() {
  group('canManageRecord', () {
    test('denies when user is null', () {
      expect(
        canManageRecord(createdBy: 'u1', currentUserId: null, isOwner: false),
        isFalse,
      );
    });

    test('allows household owner', () {
      expect(
        canManageRecord(createdBy: 'other', currentUserId: 'owner', isOwner: true),
        isTrue,
      );
    });

    test('allows record creator', () {
      expect(
        canManageRecord(createdBy: 'u1', currentUserId: 'u1', isOwner: false),
        isTrue,
      );
    });

    test('denies non-owner non-creator', () {
      expect(
        canManageRecord(createdBy: 'u1', currentUserId: 'u2', isOwner: false),
        isFalse,
      );
    });

    test('denies when createdBy is null', () {
      expect(
        canManageRecord(createdBy: null, currentUserId: 'u1', isOwner: false),
        isFalse,
      );
    });
  });
}
