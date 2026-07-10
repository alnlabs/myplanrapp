class ExpenseSplit {
  const ExpenseSplit({
    required this.id,
    required this.expenseId,
    required this.groupMemberId,
    required this.shareType,
    required this.owedAmount,
    this.shareValue,
    this.memberName,
  });

  final String id;
  final String expenseId;
  final String groupMemberId;
  final String shareType;
  final double? shareValue;
  final double owedAmount;
  final String? memberName;

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) {
    final member = json['expense_group_members'] as Map<String, dynamic>?;
    return ExpenseSplit(
      id: json['id'] as String,
      expenseId: json['expense_id'] as String,
      groupMemberId: json['group_member_id'] as String,
      shareType: json['share_type'] as String,
      shareValue: json['share_value'] != null
          ? (json['share_value'] as num).toDouble()
          : null,
      owedAmount: (json['owed_amount'] as num).toDouble(),
      memberName: member?['display_name'] as String?,
    );
  }

  Map<String, dynamic> toRpcJson() {
    return {
      'group_member_id': groupMemberId,
      'share_type': shareType,
      'share_value': shareValue,
      'owed_amount': owedAmount,
    };
  }
}

class ExpenseSplitInput {
  const ExpenseSplitInput({
    required this.groupMemberId,
    required this.shareType,
    required this.owedAmount,
    this.shareValue,
  });

  final String groupMemberId;
  final String shareType;
  final double? shareValue;
  final double owedAmount;

  Map<String, dynamic> toRpcJson() {
    return {
      'group_member_id': groupMemberId,
      'share_type': shareType,
      if (shareValue != null) 'share_value': shareValue,
      'owed_amount': owedAmount,
    };
  }
}
