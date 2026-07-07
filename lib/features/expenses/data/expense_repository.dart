import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../shared/models/expense.dart';
import '../../auth/data/auth_repository.dart';

class ExpenseRepository {
  ExpenseRepository(this._client);

  final SupabaseClient _client;

  Future<List<ExpenseCategory>> fetchCategories() async {
    final data = await _client
        .from('expense_categories')
        .select()
        .filter('household_id', 'is', null)
        .order('sort_order');
    return (data as List)
        .map((e) => ExpenseCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Expense>> fetchExpenses(String householdId) async {
    final data = await _client
        .from('expenses')
        .select('*, expense_categories(name)')
        .eq('household_id', householdId)
        .order('expense_date', ascending: false);
    return (data as List)
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList();
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
          'paid_by': userId,
          'created_by': userId,
        })
        .select('*, expense_categories(name)')
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
        .select('*, expense_categories(name)')
        .single();
    return Expense.fromJson(data);
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
}

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.watch(supabaseClientProvider));
});

final expensesProvider = FutureProvider<List<Expense>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return [];
  return ref.watch(expenseRepositoryProvider).fetchExpenses(householdId);
});

final expenseCategoriesProvider =
    FutureProvider<List<ExpenseCategory>>((ref) async {
  return ref.watch(expenseRepositoryProvider).fetchCategories();
});

final expenseSummaryProvider = FutureProvider<List<ExpenseSummaryRow>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return [];
  final now = DateTime.now();
  return ref.watch(expenseRepositoryProvider).fetchSummary(
        householdId,
        now.month,
        now.year,
      );
});
