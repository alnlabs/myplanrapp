import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../shared/models/expense.dart';
import '../../../shared/models/expense_split.dart';
import '../../../shared/models/paginated_result.dart';
import '../../../shared/utils/paginated_page_parser.dart';
import '../../auth/data/auth_repository.dart';
import 'expense_date_filter.dart';
import 'expense_date_filter_provider.dart';

class ExpenseRepository {
  ExpenseRepository(this._client);

  final SupabaseClient _client;

  static const _expenseSelect =
      '*, expense_categories(name), household_family_members(display_name), '
      'expense_groups(name), '
      'paid_by_member:expense_group_members!expenses_paid_by_member_id_fkey(display_name)';

  static const _expenseDetailSelect =
      '$_expenseSelect, expense_splits(*, expense_group_members(display_name))';

  Future<List<ExpenseCategory>> fetchCategories({
    MoneyEntryType? entryType,
  }) async {
    final data = await _client
        .from('expense_categories')
        .select()
        .filter('household_id', 'is', null)
        .order('sort_order');
    final categories = (data as List)
        .map((e) => ExpenseCategory.fromJson(e as Map<String, dynamic>))
        .toList();
    if (entryType == MoneyEntryType.expense) {
      return categories.where((c) => c.isExpenseCategory).toList();
    }
    if (entryType == MoneyEntryType.income) {
      return categories.where((c) => c.isIncomeCategory).toList();
    }
    return categories;
  }

  Future<List<Expense>> fetchExpenses(
    String householdId, {
    MoneyEntryType? entryType,
    String? familyMemberId,
  }) async {
    var query = _client
        .from('expenses')
        .select(_expenseSelect)
        .eq('household_id', householdId);
    if (entryType != null) {
      query = query.eq('entry_type', entryType.dbValue);
    }
    if (familyMemberId != null) {
      query = query.eq('family_member_id', familyMemberId);
    }
    final data = await query
        .order('expense_date', ascending: false)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PaginatedResult<Expense>> fetchExpensesPage(
    String householdId, {
    required int offset,
    required int limit,
    MoneyEntryType? entryType,
    String? familyMemberId,
    DateTime? startDate,
    DateTime? endDate,
    String? groupId,
  }) async {
    var query = _client
        .from('expenses')
        .select(_expenseSelect)
        .eq('household_id', householdId);
    if (entryType != null) {
      query = query.eq('entry_type', entryType.dbValue);
    }
    if (familyMemberId != null) {
      query = query.eq('family_member_id', familyMemberId);
    }
    if (startDate != null) {
      query = query.gte('expense_date', ExpenseDateRange.toIsoDate(startDate));
    }
    if (endDate != null) {
      query = query.lte('expense_date', ExpenseDateRange.toIsoDate(endDate));
    }
    if (groupId != null) {
      query = query.eq('group_id', groupId);
    }
    final data = await query
        .order('expense_date', ascending: false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit);
    return _parsePage(data, limit);
  }

  Future<bool> hasAnyExpense(String householdId) async {
    final data = await _client
        .from('expenses')
        .select('id')
        .eq('household_id', householdId)
        .limit(1)
        .maybeSingle();
    return data != null;
  }

  PaginatedResult<Expense> _parsePage(dynamic data, int limit) {
    final parsed = parsePaginatedPage(
      data,
      limit,
      Expense.fromJson,
    );
    return PaginatedResult(
      items: parsed.items,
      hasMore: parsed.hasMore,
    );
  }

  Future<Expense> fetchExpenseDetail(String id) async {
    final data = await _client
        .from('expenses')
        .select(_expenseDetailSelect)
        .eq('id', id)
        .single();
    return Expense.fromJson(data);
  }

  Future<Expense> createExpenseWithSplits({
    required String householdId,
    required String categoryId,
    required double amount,
    required String title,
    required DateTime expenseDate,
    String? note,
    String? groupId,
    String? paidByMemberId,
    List<ExpenseSplitInput> splits = const [],
  }) async {
    final data = await _client.rpc('create_expense_with_splits', params: {
      'p_household_id': householdId,
      'p_category_id': categoryId,
      'p_amount': amount,
      'p_title': title,
      'p_expense_date': ExpenseDateRange.toIsoDate(expenseDate),
      'p_note': note,
      'p_group_id': groupId,
      'p_paid_by_member_id': paidByMemberId,
      'p_splits': splits.map((s) => s.toRpcJson()).toList(),
    });
    return fetchExpenseDetail(data['id'] as String);
  }

  Future<Expense> updateExpenseWithSplits({
    required String id,
    required String categoryId,
    required double amount,
    required String title,
    required DateTime expenseDate,
    String? note,
    String? groupId,
    String? paidByMemberId,
    List<ExpenseSplitInput> splits = const [],
  }) async {
    await _client.rpc('update_expense_with_splits', params: {
      'p_expense_id': id,
      'p_category_id': categoryId,
      'p_amount': amount,
      'p_title': title,
      'p_expense_date': ExpenseDateRange.toIsoDate(expenseDate),
      'p_note': note,
      'p_group_id': groupId,
      'p_paid_by_member_id': paidByMemberId,
      'p_splits': splits.map((s) => s.toRpcJson()).toList(),
    });
    return fetchExpenseDetail(id);
  }

  Future<Expense> createExpense({
    required String householdId,
    required String categoryId,
    required double amount,
    required String title,
    required DateTime expenseDate,
    String? note,
    String? pantryItemId,
    double? restockDelta,
    String? restockNote,
    String? recurringRuleId,
    String? sourceSubscriptionId,
    bool isRecurringInstance = false,
  }) async {
    if (pantryItemId != null && restockDelta != null) {
      final data = await _client.rpc('log_grocery_expense', params: {
        'p_household_id': householdId,
        'p_category_id': categoryId,
        'p_amount': amount,
        'p_title': title,
        'p_expense_date': expenseDate.toIso8601String().split('T').first,
        'p_note': note,
        'p_pantry_item_id': pantryItemId,
        'p_restock_delta': restockDelta,
        'p_restock_note': restockNote,
      });
      return Expense.fromJson(data as Map<String, dynamic>);
    }

    final userId = _client.auth.currentUser?.id;
    final data = await _client
        .from('expenses')
        .insert({
          'household_id': householdId,
          'category_id': categoryId,
          'amount': amount,
          'title': title,
          'note': note,
          'expense_date': expenseDate.toIso8601String().split('T').first,
          'entry_type': MoneyEntryType.expense.dbValue,
          'paid_by': userId,
          'created_by': userId,
          'recurring_rule_id': recurringRuleId,
          'source_subscription_id': sourceSubscriptionId,
          'is_recurring_instance': isRecurringInstance,
        })
        .select(_expenseSelect)
        .single();
    return Expense.fromJson(data);
  }

  Future<Expense> createIncome({
    required String householdId,
    required String categoryId,
    required double amount,
    required String familyMemberId,
    required String incomeSource,
    required DateTime incomeDate,
    String? note,
    String? recurringRuleId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    final source = incomeSource.trim();
    final data = await _client
        .from('expenses')
        .insert({
          'household_id': householdId,
          'category_id': categoryId,
          'amount': amount,
          'title': source,
          'income_source': source,
          'note': note,
          'expense_date': incomeDate.toIso8601String().split('T').first,
          'entry_type': MoneyEntryType.income.dbValue,
          'family_member_id': familyMemberId,
          'recurring_rule_id': recurringRuleId,
          'created_by': userId,
        })
        .select(_expenseSelect)
        .single();
    return Expense.fromJson(data);
  }

  Future<void> deleteExpense(String id) async {
    await _client.from('expenses').delete().eq('id', id);
  }

  Future<Expense> updateExpense({
    required String id,
    required String categoryId,
    required double amount,
    required String title,
    required DateTime expenseDate,
    String? note,
  }) async {
    final data = await _client
        .from('expenses')
        .update({
          'category_id': categoryId,
          'amount': amount,
          'title': title,
          'note': note,
          'expense_date': expenseDate.toIso8601String().split('T').first,
        })
        .eq('id', id)
        .select(_expenseSelect)
        .single();
    return Expense.fromJson(data);
  }

  Future<Expense> updateIncome({
    required String id,
    required String categoryId,
    required double amount,
    required String familyMemberId,
    required String incomeSource,
    required DateTime incomeDate,
    String? note,
  }) async {
    final source = incomeSource.trim();
    final data = await _client
        .from('expenses')
        .update({
          'category_id': categoryId,
          'amount': amount,
          'title': source,
          'income_source': source,
          'family_member_id': familyMemberId,
          'note': note,
          'expense_date': incomeDate.toIso8601String().split('T').first,
        })
        .eq('id', id)
        .select(_expenseSelect)
        .single();
    return Expense.fromJson(data);
  }

  Future<List<ExpenseSummaryRow>> fetchSummaryRange(
    String householdId,
    DateTime start,
    DateTime end,
  ) async {
    final data =
        await _client.rpc('household_expense_summary_range', params: {
      'p_household_id': householdId,
      'p_start': ExpenseDateRange.toIsoDate(start),
      'p_end': ExpenseDateRange.toIsoDate(end),
    });
    return (data as List)
        .map((e) => ExpenseSummaryRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ExpenseSummaryRow>> fetchSummary(
    String householdId,
    int month,
    int year,
  ) async {
    final data = await _client.rpc('household_expense_summary', params: {
      'p_household_id': householdId,
      'p_month': month,
      'p_year': year,
    });
    return (data as List)
        .map((e) => ExpenseSummaryRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MoneySummary> fetchMoneySummaryRange(
    String householdId,
    DateTime start,
    DateTime end,
  ) async {
    final data = await _client.rpc('household_money_summary_range', params: {
      'p_household_id': householdId,
      'p_start': ExpenseDateRange.toIsoDate(start),
      'p_end': ExpenseDateRange.toIsoDate(end),
    });
    final rows = data as List;
    if (rows.isEmpty) {
      return const MoneySummary(
        totalSpent: 0,
        totalEarned: 0,
        netAmount: 0,
      );
    }
    return MoneySummary.fromJson(rows.first as Map<String, dynamic>);
  }

  Future<MoneySummary> fetchMoneySummary(
    String householdId,
    int month,
    int year,
  ) async {
    final data = await _client.rpc('household_money_summary', params: {
      'p_household_id': householdId,
      'p_month': month,
      'p_year': year,
    });
    final rows = data as List;
    if (rows.isEmpty) {
      return const MoneySummary(
        totalSpent: 0,
        totalEarned: 0,
        netAmount: 0,
      );
    }
    return MoneySummary.fromJson(rows.first as Map<String, dynamic>);
  }

  Future<List<MemberIncomeSummary>> fetchIncomeByMemberRange(
    String householdId,
    DateTime start,
    DateTime end,
  ) async {
    final data =
        await _client.rpc('household_income_by_member_range', params: {
      'p_household_id': householdId,
      'p_start': ExpenseDateRange.toIsoDate(start),
      'p_end': ExpenseDateRange.toIsoDate(end),
    });
    return (data as List)
        .map((e) => MemberIncomeSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MemberIncomeSummary>> fetchIncomeByMember(
    String householdId,
    int month,
    int year,
  ) async {
    final data = await _client.rpc('household_income_by_member', params: {
      'p_household_id': householdId,
      'p_month': month,
      'p_year': year,
    });
    return (data as List)
        .map((e) => MemberIncomeSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MemberIncomeSourceSummary>> fetchIncomeByMemberSource(
    String householdId,
    String familyMemberId,
    int month,
    int year,
  ) async {
    final data =
        await _client.rpc('household_income_by_member_source', params: {
      'p_household_id': householdId,
      'p_family_member_id': familyMemberId,
      'p_month': month,
      'p_year': year,
    });
    return (data as List)
        .map((e) =>
            MemberIncomeSourceSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Expense>> fetchForExport(
    String householdId,
    DateTime start,
    DateTime end, {
    MoneyEntryType? entryType,
    String? familyMemberId,
    int limit = 5000,
  }) async {
    var query = _client
        .from('expenses')
        .select(_expenseSelect)
        .eq('household_id', householdId)
        .gte('expense_date', ExpenseDateRange.toIsoDate(start))
        .lte('expense_date', ExpenseDateRange.toIsoDate(end));
    if (entryType != null) {
      query = query.eq('entry_type', entryType.dbValue);
    }
    if (familyMemberId != null) {
      query = query.eq('family_member_id', familyMemberId);
    }
    final data = await query
        .order('expense_date', ascending: false)
        .limit(limit + 1);
    final rows = (data as List)
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList();
    return rows.length > limit ? rows.sublist(0, limit) : rows;
  }

  Future<List<Expense>> fetchIncomeForExport(
    String householdId,
    int month,
    int year, {
    MoneyEntryType? entryType,
    String? familyMemberId,
    int limit = 5000,
  }) {
    return fetchForExport(
      householdId,
      DateTime(year, month, 1),
      DateTime(year, month + 1, 0),
      entryType: entryType,
      familyMemberId: familyMemberId,
      limit: limit,
    );
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.watch(supabaseClientProvider));
});

final hasAnyExpenseProvider = FutureProvider<bool>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return false;
  return ref.watch(expenseRepositoryProvider).hasAnyExpense(householdId);
});

final expenseCategoriesProvider =
    FutureProvider<List<ExpenseCategory>>((ref) async {
  return ref
      .watch(expenseRepositoryProvider)
      .fetchCategories(entryType: MoneyEntryType.expense);
});

final incomeCategoriesProvider =
    FutureProvider<List<ExpenseCategory>>((ref) async {
  return ref
      .watch(expenseRepositoryProvider)
      .fetchCategories(entryType: MoneyEntryType.income);
});

final expenseSummaryProvider = FutureProvider<List<ExpenseSummaryRow>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return [];
  final range = ref.watch(expenseDateRangeProvider);
  return ref.watch(expenseRepositoryProvider).fetchSummaryRange(
        householdId,
        range.start,
        range.end,
      );
});

final moneySummaryProvider = FutureProvider<MoneySummary>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) {
    return const MoneySummary(totalSpent: 0, totalEarned: 0, netAmount: 0);
  }
  final range = ref.watch(expenseDateRangeProvider);
  return ref.watch(expenseRepositoryProvider).fetchMoneySummaryRange(
        householdId,
        range.start,
        range.end,
      );
});

final memberIncomeSummaryProvider =
    FutureProvider<List<MemberIncomeSummary>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return [];
  final range = ref.watch(expenseDateRangeProvider);
  return ref.watch(expenseRepositoryProvider).fetchIncomeByMemberRange(
        householdId,
        range.start,
        range.end,
      );
});

final memberIncomeSourceSummaryProvider =
    FutureProvider.family<List<MemberIncomeSourceSummary>, String>(
        (ref, familyMemberId) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return [];
  final now = DateTime.now();
  return ref.watch(expenseRepositoryProvider).fetchIncomeByMemberSource(
        householdId,
        familyMemberId,
        now.month,
        now.year,
      );
});
