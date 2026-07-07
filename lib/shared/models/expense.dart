class ExpenseCategory {
  const ExpenseCategory({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id'] as String,
      name: json['name'] as String,
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
    this.note,
    this.categoryName,
    this.pantryItemId,
  });

  final String id;
  final String householdId;
  final String categoryId;
  final double amount;
  final String title;
  final DateTime expenseDate;
  final String? note;
  final String? categoryName;
  final String? pantryItemId;

  factory Expense.fromJson(Map<String, dynamic> json) {
    final category = json['expense_categories'] as Map<String, dynamic>?;
    return Expense(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      categoryId: json['category_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      title: json['title'] as String,
      expenseDate: DateTime.parse(json['expense_date'] as String),
      note: json['note'] as String?,
      categoryName: category?['name'] as String?,
      pantryItemId: json['pantry_item_id'] as String?,
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
