import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/models/account_deletion_status.dart';

void main() {
  group('AccountDeletionStatus.fromProfile', () {
    test('active when deletedAt is null', () {
      final status = AccountDeletionStatus.fromProfile(null);
      expect(status.isActive, isTrue);
      expect(status.isPending, isFalse);
      expect(status.purgeAt, isNull);
    });

    test('pending within grace period', () {
      final deletedAt = DateTime.now().subtract(const Duration(days: 5));
      final status = AccountDeletionStatus.fromProfile(deletedAt);
      expect(status.isPending, isTrue);
      expect(status.deletedAt, deletedAt);
      expect(status.purgeAt, deletedAt.add(const Duration(days: 30)));
    });

    test('expired after grace period', () {
      final deletedAt = DateTime.now().subtract(const Duration(days: 31));
      final status = AccountDeletionStatus.fromProfile(deletedAt);
      expect(status.isExpired, isTrue);
      expect(status.isPending, isFalse);
    });
  });

  group('AccountDeletionExpiredException', () {
    test('has descriptive toString', () {
      expect(
        const AccountDeletionExpiredException().toString(),
        contains('grace period'),
      );
    });
  });
}
