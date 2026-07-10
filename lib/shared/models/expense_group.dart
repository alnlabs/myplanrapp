class ExpenseGroup {
  const ExpenseGroup({
    required this.id,
    required this.householdId,
    required this.name,
    required this.groupType,
    this.createdBy,
    this.memberCount,
  });

  final String id;
  final String householdId;
  final String name;
  final String groupType;
  final String? createdBy;
  final int? memberCount;

  bool get isShared => groupType == 'shared';

  factory ExpenseGroup.fromJson(Map<String, dynamic> json) {
    final members = json['expense_group_members'];
    int? count;
    if (members is List) {
      count = members.length;
    }
    return ExpenseGroup(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      name: json['name'] as String,
      groupType: json['group_type'] as String,
      createdBy: json['created_by'] as String?,
      memberCount: count,
    );
  }
}

class ExpenseGroupMember {
  const ExpenseGroupMember({
    required this.id,
    required this.groupId,
    required this.displayName,
    this.userId,
    this.familyMemberId,
    this.guestEmail,
    this.inviteStatus = 'active',
  });

  final String id;
  final String groupId;
  final String displayName;
  final String? userId;
  final String? familyMemberId;
  final String? guestEmail;
  final String inviteStatus;

  bool get isPending => inviteStatus == 'pending';

  factory ExpenseGroupMember.fromJson(Map<String, dynamic> json) {
    return ExpenseGroupMember(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      displayName: json['display_name'] as String,
      userId: json['user_id'] as String?,
      familyMemberId: json['family_member_id'] as String?,
      guestEmail: json['guest_email'] as String?,
      inviteStatus: json['invite_status'] as String? ?? 'active',
    );
  }
}

class ExpenseGroupBalance {
  const ExpenseGroupBalance({
    required this.groupMemberId,
    required this.displayName,
    required this.paidTotal,
    required this.owedTotal,
    required this.settledIn,
    required this.settledOut,
    required this.netBalance,
  });

  final String groupMemberId;
  final String displayName;
  final double paidTotal;
  final double owedTotal;
  final double settledIn;
  final double settledOut;
  final double netBalance;

  factory ExpenseGroupBalance.fromJson(Map<String, dynamic> json) {
    return ExpenseGroupBalance(
      groupMemberId: json['group_member_id'] as String,
      displayName: json['display_name'] as String,
      paidTotal: (json['paid_total'] as num).toDouble(),
      owedTotal: (json['owed_total'] as num).toDouble(),
      settledIn: (json['settled_in'] as num).toDouble(),
      settledOut: (json['settled_out'] as num).toDouble(),
      netBalance: (json['net_balance'] as num).toDouble(),
    );
  }
}

class SuggestedSettlement {
  const SuggestedSettlement({
    required this.fromMemberId,
    required this.fromName,
    required this.toMemberId,
    required this.toName,
    required this.amount,
  });

  final String fromMemberId;
  final String fromName;
  final String toMemberId;
  final String toName;
  final double amount;
}
