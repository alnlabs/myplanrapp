import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/models/expense_group.dart';
import '../../../shared/models/expense_split.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../data/expense_groups_repository.dart';
import '../utils/expense_group_split_builder.dart';
import '../utils/expense_split_calculator.dart';

class ExpenseGroupFields extends ConsumerStatefulWidget {
  const ExpenseGroupFields({
    super.key,
    required this.amountController,
    this.initialGroupId,
    this.initialPaidByMemberId,
    this.initialParticipantIds,
    this.initialShareType = ExpenseShareType.equal,
    this.initialSplits,
    this.onChanged,
  });

  final TextEditingController amountController;
  final String? initialGroupId;
  final String? initialPaidByMemberId;
  final Set<String>? initialParticipantIds;
  final ExpenseShareType initialShareType;
  final List<ExpenseSplit>? initialSplits;
  final VoidCallback? onChanged;

  @override
  ConsumerState<ExpenseGroupFields> createState() => ExpenseGroupFieldsState();
}

class ExpenseGroupFieldsState extends ConsumerState<ExpenseGroupFields> {
  String? _groupId;
  String? _paidByMemberId;
  ExpenseShareType _shareType = ExpenseShareType.equal;
  final _participants = <String>{};
  final _exactControllers = <String, TextEditingController>{};
  final _percentControllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _groupId = widget.initialGroupId;
    _paidByMemberId = widget.initialPaidByMemberId;
    _shareType = widget.initialShareType;
    if (widget.initialParticipantIds != null) {
      _participants.addAll(widget.initialParticipantIds!);
    }
  }

  @override
  void dispose() {
    for (final c in _exactControllers.values) {
      c.dispose();
    }
    for (final c in _percentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? get groupId => _groupId;

  String? get paidByMemberId => _paidByMemberId;

  List<ExpenseGroupMember> _activeMembers(List<ExpenseGroupMember> members) =>
      members.where((m) => !m.isPending).toList();

  List<ExpenseSplitInput>? buildSplits(double amount) {
    final exactTexts = {
      for (final id in _participants) id: _exactControllers[id]?.text ?? '',
    };
    final percentTexts = {
      for (final id in _participants) id: _percentControllers[id]?.text ?? '',
    };
    return ExpenseGroupSplitBuilder.build(
      groupId: _groupId,
      group: _groupId == null
          ? null
          : ref.read(expenseGroupProvider(_groupId!)).valueOrNull,
      participants: _participants,
      shareType: _shareType,
      paidByMemberId: _paidByMemberId,
      amount: amount,
      exactTextsByMemberId: exactTexts,
      percentTextsByMemberId: percentTexts,
    );
  }

  void _notify() => widget.onChanged?.call();

  void _ensureControllers(List<ExpenseGroupMember> members) {
    for (final m in members) {
      _exactControllers.putIfAbsent(m.id, TextEditingController.new);
      _percentControllers.putIfAbsent(m.id, TextEditingController.new);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(expenseGroupsProvider);
    final membersAsync = _groupId == null
        ? const AsyncValue<List<ExpenseGroupMember>>.data([])
        : ref.watch(expenseGroupMembersProvider(_groupId!));
    final group = _groupId == null
        ? null
        : ref.watch(expenseGroupProvider(_groupId!)).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        groupsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox.shrink(),
          data: (groups) => DropdownButtonFormField<String?>(
            value: _groupId,
            decoration:
                const InputDecoration(labelText: AppStrings.expenseGroup),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text(AppStrings.noGroup),
              ),
              ...groups.map(
                (g) => DropdownMenuItem(
                  value: g.id,
                  child: Text(g.name),
                ),
              ),
            ],
            onChanged: (v) => setState(() {
              _groupId = v;
              _paidByMemberId = null;
              _participants.clear();
              _notify();
            }),
          ),
        ),
        if (_groupId != null)
          membersAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (members) {
              final active = _activeMembers(members);
              _ensureControllers(active);
              if (_participants.isEmpty && active.isNotEmpty) {
                _participants.addAll(active.map((m) => m.id));
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: _paidByMemberId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: AppStrings.paidByMember,
                      helperText: AppStrings.paidByHint,
                    ),
                    items: active
                        .map(
                          (m) => DropdownMenuItem(
                            value: m.id,
                            child: Text(m.displayName),
                          ),
                        )
                        .toList(),
                    // Exactly one payer is required for shared expenses so the
                    // split balances can be attributed correctly.
                    validator: group?.isShared == true
                        ? (v) => v == null ? AppStrings.requiredField : null
                        : null,
                    onChanged: (v) => setState(() {
                      _paidByMemberId = v;
                      _notify();
                    }),
                  ),
                  if (group?.isShared == true) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.splitBetween,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      AppStrings.splitBetweenHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    ...active.map(
                      (m) => CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(m.displayName),
                        value: _participants.contains(m.id),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _participants.add(m.id);
                          } else {
                            _participants.remove(m.id);
                          }
                          _notify();
                        }),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<ExpenseShareType>(
                      value: _shareType,
                      decoration:
                          const InputDecoration(labelText: AppStrings.splitType),
                      items: const [
                        DropdownMenuItem(
                          value: ExpenseShareType.equal,
                          child: Text(AppStrings.splitEqual),
                        ),
                        DropdownMenuItem(
                          value: ExpenseShareType.exact,
                          child: Text(AppStrings.splitExact),
                        ),
                        DropdownMenuItem(
                          value: ExpenseShareType.percent,
                          child: Text(AppStrings.splitPercent),
                        ),
                      ],
                      onChanged: (v) => setState(() {
                        _shareType = v ?? ExpenseShareType.equal;
                        _notify();
                      }),
                    ),
                    if (_shareType == ExpenseShareType.exact)
                      ...active
                          .where((m) => _participants.contains(m.id))
                          .map(
                            (m) => Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: AppTextField(
                                controller: _exactControllers[m.id]!,
                                label: m.displayName,
                                prefixText: '₹ ',
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: Validators.positiveNumber,
                              ),
                            ),
                          ),
                    if (_shareType == ExpenseShareType.percent)
                      ...active
                          .where((m) => _participants.contains(m.id))
                          .map(
                            (m) => Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: AppTextField(
                                controller: _percentControllers[m.id]!,
                                label: '${m.displayName} %',
                                suffixText: '%',
                                keyboardType: TextInputType.number,
                                validator: Validators.positiveNumber,
                              ),
                            ),
                          ),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }
}
