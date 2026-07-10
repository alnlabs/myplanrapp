import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../shared/models/expense.dart';
import '../../../shared/models/recurring_money_rule.dart';
import '../../auth/data/auth_repository.dart';
import 'expense_date_filter.dart';

class RecurringMoneyRuleRepository {
  RecurringMoneyRuleRepository(this._client);

  final SupabaseClient _client;

  static const _select =
      '*, expense_categories(name), household_family_members(display_name), '
      'expense_groups(name), subscriptions(name)';

  Future<List<RecurringMoneyRule>> fetchRules(
    String householdId, {
    String? entryType,
  }) async {
    var query = _client
        .from('recurring_money_rules')
        .select(_select)
        .eq('household_id', householdId);
    if (entryType != null) {
      query = query.eq('entry_type', entryType);
    }
    final data = await query.order('next_due_date');
    return (data as List)
        .map((e) => RecurringMoneyRule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RecurringMoneyRule>> fetchIncomeRulesForMember(
    String familyMemberId,
  ) async {
    final data = await _client
        .from('recurring_money_rules')
        .select(_select)
        .eq('family_member_id', familyMemberId)
        .eq('entry_type', 'income')
        .order('next_due_date');
    return (data as List)
        .map((e) => RecurringMoneyRule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RecurringMoneyRule>> fetchDueRules(
    String householdId, {
    String? entryType,
  }) async {
    final today = ExpenseDateRange.toIsoDate(DateTime.now());
    var query = _client
        .from('recurring_money_rules')
        .select(_select)
        .eq('household_id', householdId)
        .eq('is_active', true)
        .lte('next_due_date', today);
    if (entryType != null) {
      query = query.eq('entry_type', entryType);
    }
    final data = await query.order('next_due_date');
    return (data as List)
        .map((e) => RecurringMoneyRule.fromJson(e as Map<String, dynamic>))
        .where((r) => r.isDue)
        .toList();
  }

  Future<RecurringMoneyRule> createIncomeRule({
    required String householdId,
    required String familyMemberId,
    required String incomeSource,
    required String categoryId,
    required double amount,
    required String frequency,
    required DateTime startDate,
    required DateTime nextDueDate,
    int intervalCount = 1,
    int? dayOfMonth,
    String? note,
  }) async {
    final userId = _client.auth.currentUser?.id;
    final source = incomeSource.trim();
    final data = await _client
        .from('recurring_money_rules')
        .insert({
          'household_id': householdId,
          'created_by': userId,
          'entry_type': 'income',
          'title': source,
          'income_source': source,
          'family_member_id': familyMemberId,
          'category_id': categoryId,
          'amount': amount,
          'frequency': frequency,
          'interval_count': intervalCount,
          'day_of_month': dayOfMonth,
          'start_date': ExpenseDateRange.toIsoDate(startDate),
          'next_due_date': ExpenseDateRange.toIsoDate(nextDueDate),
          'note': note,
        })
        .select(_select)
        .single();
    return RecurringMoneyRule.fromJson(data);
  }

  Future<RecurringMoneyRule> createExpenseRule({
    required String householdId,
    required String title,
    required String categoryId,
    required double amount,
    required String frequency,
    required DateTime startDate,
    required DateTime nextDueDate,
    int intervalCount = 1,
    int? dayOfMonth,
    int? dayOfWeek,
    int? monthOfYear,
    String? note,
    bool autoLog = false,
    String? groupId,
    String? paidByMemberId,
    String? subscriptionId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    final data = await _client
        .from('recurring_money_rules')
        .insert({
          'household_id': householdId,
          'created_by': userId,
          'entry_type': 'expense',
          'title': title.trim(),
          'category_id': categoryId,
          'amount': amount,
          'frequency': frequency,
          'interval_count': intervalCount,
          'day_of_month': dayOfMonth,
          'day_of_week': dayOfWeek,
          'month_of_year': monthOfYear,
          'start_date': ExpenseDateRange.toIsoDate(startDate),
          'next_due_date': ExpenseDateRange.toIsoDate(nextDueDate),
          'note': note,
          'auto_log': autoLog,
          'group_id': groupId,
          'paid_by_member_id': paidByMemberId,
          'subscription_id': subscriptionId,
        })
        .select(_select)
        .single();
    return RecurringMoneyRule.fromJson(data);
  }

  Future<void> deleteRule(String id) async {
    await _client.from('recurring_money_rules').delete().eq('id', id);
  }

  Future<void> setRuleActive(String id, bool isActive) async {
    await _client
        .from('recurring_money_rules')
        .update({'is_active': isActive})
        .eq('id', id);
  }

  Future<RecurringMoneyRule> advanceRule(String ruleId) async {
    final data = await _client.rpc(
      'advance_recurring_money_rule',
      params: {'p_rule_id': ruleId},
    );
    return RecurringMoneyRule.fromJson(data as Map<String, dynamic>);
  }

  Future<RecurringMoneyRule> snoozeRule(String ruleId, DateTime until) async {
    final data = await _client.rpc(
      'snooze_recurring_money_rule',
      params: {
        'p_rule_id': ruleId,
        'p_snooze_until': ExpenseDateRange.toIsoDate(until),
      },
    );
    return RecurringMoneyRule.fromJson(data as Map<String, dynamic>);
  }

  Future<Expense> logRecurringExpense(String ruleId, {DateTime? date}) async {
    final data = await _client.rpc(
      'log_recurring_expense',
      params: {
        'p_rule_id': ruleId,
        'p_expense_date': ExpenseDateRange.toIsoDate(date ?? DateTime.now()),
      },
    );
    return Expense.fromJson(data as Map<String, dynamic>);
  }

  Future<int> processAutoLogDueExpenses(String householdId) async {
    final due = await fetchDueRules(householdId, entryType: 'expense');
    var count = 0;
    for (final rule in due) {
      if (rule.autoLog) {
        await logRecurringExpense(rule.id);
        count++;
      }
    }
    return count;
  }
}

final recurringMoneyRuleRepositoryProvider =
    Provider<RecurringMoneyRuleRepository>((ref) {
  return RecurringMoneyRuleRepository(ref.watch(supabaseClientProvider));
});

final recurringExpenseRulesProvider =
    FutureProvider<List<RecurringMoneyRule>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return [];
  return ref
      .watch(recurringMoneyRuleRepositoryProvider)
      .fetchRules(householdId, entryType: 'expense');
});

final memberRecurringIncomeProvider =
    FutureProvider.family<List<RecurringMoneyRule>, String>(
        (ref, familyMemberId) async {
  return ref
      .watch(recurringMoneyRuleRepositoryProvider)
      .fetchIncomeRulesForMember(familyMemberId);
});

final dueRecurringIncomeProvider =
    FutureProvider<List<RecurringMoneyRule>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return [];
  return ref.watch(recurringMoneyRuleRepositoryProvider).fetchDueRules(
        householdId,
        entryType: 'income',
      );
});

final dueRecurringExpenseProvider =
    FutureProvider<List<RecurringMoneyRule>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return [];
  return ref.watch(recurringMoneyRuleRepositoryProvider).fetchDueRules(
        householdId,
        entryType: 'expense',
      );
});
