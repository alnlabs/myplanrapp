import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../shared/models/expense.dart';
import '../../../shared/models/expense_group.dart';
import '../../../shared/models/expense_split.dart';
import '../../auth/data/auth_repository.dart';
import 'expense_date_filter.dart';

class ExpenseGroupsRepository {
  ExpenseGroupsRepository(this._client);

  final SupabaseClient _client;

  Future<List<ExpenseGroup>> fetchGroups(String householdId) async {
    final data = await _client
        .from('expense_groups')
        .select('*, expense_group_members(id)')
        .eq('household_id', householdId)
        .order('name');
    return (data as List)
        .map((e) => ExpenseGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ExpenseGroup?> fetchGroup(String groupId) async {
    final data = await _client
        .from('expense_groups')
        .select('*, expense_group_members(id)')
        .eq('id', groupId)
        .maybeSingle();
    if (data == null) return null;
    return ExpenseGroup.fromJson(data);
  }

  Future<List<ExpenseGroupMember>> fetchMembers(String groupId) async {
    final data = await _client
        .from('expense_group_members')
        .select()
        .eq('group_id', groupId)
        .order('display_name');
    return (data as List)
        .map((e) => ExpenseGroupMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> createGroup({
    required String householdId,
    required String name,
    required String groupType,
    required List<ExpenseGroupMemberInput> members,
  }) async {
    final userId = _client.auth.currentUser?.id;
    final group = await _client
        .from('expense_groups')
        .insert({
          'household_id': householdId,
          'name': name,
          'group_type': groupType,
          'created_by': userId,
        })
        .select()
        .single();
    final groupId = group['id'] as String;
    if (members.isNotEmpty) {
      await _client.from('expense_group_members').insert(
            members
                .map(
                  (m) => {
                    'group_id': groupId,
                    'display_name': m.displayName,
                    'user_id': m.userId,
                    'family_member_id': m.familyMemberId,
                    'guest_email': m.guestEmail,
                    'invite_status': m.inviteStatus,
                  },
                )
                .toList(),
          );
    }
    return groupId;
  }

  Future<List<ExpenseGroupBalance>> fetchBalances(String groupId) async {
    final data = await _client.rpc('expense_group_balances', params: {
      'p_group_id': groupId,
    });
    return (data as List)
        .map((e) => ExpenseGroupBalance.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> recordSettlement({
    required String groupId,
    required String fromMemberId,
    required String toMemberId,
    required double amount,
    String? note,
  }) async {
    await _client.rpc('record_expense_settlement', params: {
      'p_group_id': groupId,
      'p_from_member_id': fromMemberId,
      'p_to_member_id': toMemberId,
      'p_amount': amount,
      'p_note': note,
    });
  }

  Future<List<Expense>> fetchGroupExpenses(
    String groupId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client
        .from('expenses')
        .select(
          '*, expense_categories(name), expense_groups(name), '
          'expense_splits(*, expense_group_members(display_name))',
        )
        .eq('group_id', groupId)
        .eq('entry_type', 'expense');
    if (startDate != null) {
      query = query.gte('expense_date', ExpenseDateRange.toIsoDate(startDate));
    }
    if (endDate != null) {
      query = query.lte('expense_date', ExpenseDateRange.toIsoDate(endDate));
    }
    final data = await query
        .order('expense_date', ascending: false);
    return (data as List)
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ExpenseSplit>> fetchExpenseSplits(String expenseId) async {
    final data = await _client
        .from('expense_splits')
        .select('*, expense_group_members(display_name)')
        .eq('expense_id', expenseId);
    return (data as List)
        .map((e) => ExpenseSplit.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class ExpenseGroupMemberInput {
  const ExpenseGroupMemberInput({
    required this.displayName,
    this.userId,
    this.familyMemberId,
    this.guestEmail,
    this.inviteStatus = 'active',
  });

  final String displayName;
  final String? userId;
  final String? familyMemberId;
  final String? guestEmail;
  final String inviteStatus;
}

final expenseGroupsRepositoryProvider =
    Provider<ExpenseGroupsRepository>((ref) {
  return ExpenseGroupsRepository(ref.watch(supabaseClientProvider));
});

final expenseGroupsProvider = FutureProvider<List<ExpenseGroup>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return [];
  return ref.watch(expenseGroupsRepositoryProvider).fetchGroups(householdId);
});

final expenseGroupProvider =
    FutureProvider.family<ExpenseGroup?, String>((ref, groupId) async {
  return ref.watch(expenseGroupsRepositoryProvider).fetchGroup(groupId);
});

final expenseGroupMembersProvider =
    FutureProvider.family<List<ExpenseGroupMember>, String>((ref, groupId) async {
  return ref.watch(expenseGroupsRepositoryProvider).fetchMembers(groupId);
});

final expenseGroupBalancesProvider =
    FutureProvider.family<List<ExpenseGroupBalance>, String>((ref, groupId) async {
  return ref.watch(expenseGroupsRepositoryProvider).fetchBalances(groupId);
});

final expenseGroupExpensesProvider = FutureProvider.family<
    List<Expense>,
    (String, ExpenseDateRange)>((ref, key) async {
  final (groupId, range) = key;
  return ref.read(expenseGroupsRepositoryProvider).fetchGroupExpenses(
        groupId,
        startDate: range.start,
        endDate: range.end,
      );
});
