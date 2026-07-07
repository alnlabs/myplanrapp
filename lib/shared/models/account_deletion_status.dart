class AccountDeletionStatus {
  const AccountDeletionStatus._({
    required this.state,
    this.deletedAt,
    this.purgeAt,
  });

  final AccountDeletionState state;
  final DateTime? deletedAt;
  final DateTime? purgeAt;

  bool get isActive => state == AccountDeletionState.active;
  bool get isPending => state == AccountDeletionState.pending;
  bool get isExpired => state == AccountDeletionState.expired;

  factory AccountDeletionStatus.active() {
    return const AccountDeletionStatus._(state: AccountDeletionState.active);
  }

  factory AccountDeletionStatus.fromProfile(DateTime? deletedAt) {
    if (deletedAt == null) {
      return AccountDeletionStatus.active();
    }

    final purgeAt = deletedAt.add(const Duration(days: 30));
    if (!DateTime.now().isBefore(purgeAt)) {
      return AccountDeletionStatus._(
        state: AccountDeletionState.expired,
        deletedAt: deletedAt,
        purgeAt: purgeAt,
      );
    }

    return AccountDeletionStatus._(
      state: AccountDeletionState.pending,
      deletedAt: deletedAt,
      purgeAt: purgeAt,
    );
  }
}

enum AccountDeletionState { active, pending, expired }

class AccountDeletionExpiredException implements Exception {
  const AccountDeletionExpiredException();

  @override
  String toString() => 'Account deletion grace period has ended';
}
