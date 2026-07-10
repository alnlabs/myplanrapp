import 'expense_split.dart';

enum MoneyEntryType {
  expense,
  income;

  String get dbValue => name;

  static MoneyEntryType fromDb(String? value) {
    return value == 'income' ? MoneyEntryType.income : MoneyEntryType.expense;
  }
}

class ExpenseCategory {
  const ExpenseCategory({
    required this.id,
    required this.name,
    this.categoryKind = 'expense',
  });

  final String id;
  final String name;
  final String categoryKind;

  bool get isExpenseCategory =>
      categoryKind == 'expense' || categoryKind == 'both';

  bool get isIncomeCategory =>
      categoryKind == 'income' || categoryKind == 'both';

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      categoryKind: json['category_kind'] as String? ?? 'expense',
    );
  }
}

class Expense {
  const Expense({
    required this.id,
    required this.householdId,
    required this.categoryId,
    required this.amount,
    required this.title,
    required this.expenseDate,
    this.entryType = MoneyEntryType.expense,
    this.note,
    this.categoryName,
    this.pantryItemId,
    this.createdBy,
    this.familyMemberId,
    this.familyMemberName,
    this.incomeSource,
    this.groupId,
    this.groupName,
    this.paidByMemberId,
    this.paidByMemberName,
    this.splits = const [],
  });

  final String id;
  final String householdId;
  final String categoryId;
  final double amount;
  final String title;
  final DateTime expenseDate;
  final MoneyEntryType entryType;
  final String? note;
  final String? categoryName;
  final String? pantryItemId;
  final String? createdBy;
  final String? familyMemberId;
  final String? familyMemberName;
  final String? incomeSource;
  final String? groupId;
  final String? groupName;
  final String? paidByMemberId;
  final String? paidByMemberName;
  final List<ExpenseSplit> splits;

  bool get hasGroup => groupId != null;

  bool get isIncome => entryType == MoneyEntryType.income;

  String get displaySource =>
      (incomeSource != null && incomeSource!.trim().isNotEmpty)
          ? incomeSource!.trim()
          : title;

  factory Expense.fromJson(Map<String, dynamic> json) {
    final category = json['expense_categories'] as Map<String, dynamic>?;
    final member = json['household_family_members'] as Map<String, dynamic>?;
    final group = json['expense_groups'] as Map<String, dynamic>?;
    final paidMember =
        json['paid_by_member'] as Map<String, dynamic>?;
    final splitsJson = json['expense_splits'];
    final splits = splitsJson is List
        ? splitsJson
            .map((e) => ExpenseSplit.fromJson(e as Map<String, dynamic>))
            .toList()
        : <ExpenseSplit>[];
    return Expense(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      categoryId: json['category_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      title: json['title'] as String,
      expenseDate: DateTime.parse(json['expense_date'] as String),
      entryType: MoneyEntryType.fromDb(json['entry_type'] as String?),
      note: json['note'] as String?,
      categoryName: category?['name'] as String?,
      pantryItemId: json['pantry_item_id'] as String?,
      createdBy: json['created_by'] as String?,
      familyMemberId: json['family_member_id'] as String?,
      familyMemberName: member?['display_name'] as String?,
      incomeSource: json['income_source'] as String?,
      groupId: json['group_id'] as String?,
      groupName: group?['name'] as String?,
      paidByMemberId: json['paid_by_member_id'] as String?,
      paidByMemberName: paidMember?['display_name'] as String?,
      splits: splits,
    );
  }
}

class ExpenseSummaryRow {
  const ExpenseSummaryRow({
    required this.categoryId,
    required this.categoryName,
    required this.totalAmount,
  });

  final String categoryId;
  final String categoryName;
  final double totalAmount;

  factory ExpenseSummaryRow.fromJson(Map<String, dynamic> json) {
    return ExpenseSummaryRow(
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
    );
  }
}

class MoneySummary {
  const MoneySummary({
    required this.totalSpent,
    required this.totalEarned,
    required this.netAmount,
  });

  final double totalSpent;
  final double totalEarned;
  final double netAmount;

  factory MoneySummary.fromJson(Map<String, dynamic> json) {
    return MoneySummary(
      totalSpent: (json['total_spent'] as num).toDouble(),
      totalEarned: (json['total_earned'] as num).toDouble(),
      netAmount: (json['net_amount'] as num).toDouble(),
    );
  }
}

class MemberIncomeSummary {
  const MemberIncomeSummary({
    required this.familyMemberId,
    required this.memberName,
    required this.earnedTotal,
  });

  final String familyMemberId;
  final String memberName;
  final double earnedTotal;

  factory MemberIncomeSummary.fromJson(Map<String, dynamic> json) {
    return MemberIncomeSummary(
      familyMemberId: json['family_member_id'] as String,
      memberName: json['member_name'] as String,
      earnedTotal: (json['earned_total'] as num).toDouble(),
    );
  }
}

class MemberIncomeSourceSummary {
  const MemberIncomeSourceSummary({
    required this.incomeSource,
    required this.earnedTotal,
  });

  final String incomeSource;
  final double earnedTotal;

  factory MemberIncomeSourceSummary.fromJson(Map<String, dynamic> json) {
    return MemberIncomeSourceSummary(
      incomeSource: json['income_source'] as String,
      earnedTotal: (json['earned_total'] as num).toDouble(),
    );
  }
}
