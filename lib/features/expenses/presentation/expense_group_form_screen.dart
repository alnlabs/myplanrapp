import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/models/family_member.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/offline_guard.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/form_error_banner.dart';
import '../../../shared/widgets/form_screen_body.dart';
import '../../auth/data/auth_repository.dart';
import '../../household/data/family_repository.dart';
import '../data/expense_groups_repository.dart';

class ExpenseGroupFormScreen extends ConsumerStatefulWidget {
  const ExpenseGroupFormScreen({super.key});

  @override
  ConsumerState<ExpenseGroupFormScreen> createState() =>
      _ExpenseGroupFormScreenState();
}

class _ExpenseGroupFormScreenState extends ConsumerState<ExpenseGroupFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  var _groupType = 'organizational';
  final _selectedFamilyIds = <String>{};
  final _guests = <ExpenseGroupMemberInput>[];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _addGuest() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.addGuestMember),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: nameController,
              label: AppStrings.guestName,
              validator: Validators.required,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: emailController,
              label: AppStrings.guestEmailOptional,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
    if (saved != true) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    final email = emailController.text.trim();
    setState(() {
      _guests.add(
        ExpenseGroupMemberInput(
          displayName: name,
          guestEmail: email.isEmpty ? null : email,
          inviteStatus: email.isEmpty ? 'active' : 'pending',
        ),
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final roster = await ref.read(familyRosterProvider.future);
    final members = <ExpenseGroupMemberInput>[
      ...roster
          .where((m) => _selectedFamilyIds.contains(m.id))
          .map(
            (FamilyMember m) => ExpenseGroupMemberInput(
              displayName: m.listLabel,
              userId: m.userId,
              familyMemberId: m.id,
              inviteStatus: m.isPendingInvite ? 'pending' : 'active',
            ),
          ),
      ..._guests,
    ];

    if (_groupType == 'shared' && members.length < 2) {
      setState(() => _error = AppStrings.sharedGroupMinMembers);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      ref.ensureOnline();
      final profile = await ref.read(userProfileProvider.future);
      final householdId = profile?.activeHouseholdId;
      if (householdId == null) throw Exception(AppStrings.noHousehold);

      final groupId = await ref.read(expenseGroupsRepositoryProvider).createGroup(
            householdId: householdId,
            name: _name.text.trim(),
            groupType: _groupType,
            members: members,
          );
      ref.invalidate(expenseGroupsProvider);
      if (mounted) context.go('/expenses/groups/$groupId');
    } catch (e) {
      setState(() => _error = ApiErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rosterAsync = ref.watch(familyRosterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.addExpenseGroup)),
      body: FormScreenBody(
        formKey: _formKey,
        children: [
          AppTextField(
            controller: _name,
            label: AppStrings.groupName,
            validator: Validators.required,
          ),
          const SizedBox(height: kFormFieldSpacing),
          DropdownButtonFormField<String>(
            value: _groupType,
            decoration: const InputDecoration(labelText: AppStrings.groupType),
            items: const [
              DropdownMenuItem(
                value: 'organizational',
                child: Text(AppStrings.groupTypeOrganizational),
              ),
              DropdownMenuItem(
                value: 'shared',
                child: Text(AppStrings.groupTypeShared),
              ),
            ],
            onChanged: (v) => setState(() => _groupType = v ?? 'organizational'),
          ),
          const SizedBox(height: kFormFieldSpacing),
          Text(
            AppStrings.groupMembers,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          rosterAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => FormAsyncFieldError(
              message: AppStrings.errorGeneric,
              onRetry: () => ref.invalidate(familyRosterProvider),
            ),
            data: (roster) => Column(
              children: roster
                  .map(
                    (m) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(m.listLabel),
                      value: _selectedFamilyIds.contains(m.id),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _selectedFamilyIds.add(m.id);
                        } else {
                          _selectedFamilyIds.remove(m.id);
                        }
                      }),
                    ),
                  )
                  .toList(),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addGuest,
              icon: const Icon(Icons.person_add_outlined),
              label: const Text(AppStrings.addGuestMember),
            ),
          ),
          ..._guests.map(
            (g) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(g.displayName),
              subtitle: g.guestEmail != null ? Text(g.guestEmail!) : null,
            ),
          ),
          const SizedBox(height: 24),
          FormSaveSection(
            error: _error,
            saveLabel: AppStrings.save,
            isLoading: _loading,
            onSave: _save,
          ),
        ],
      ),
    );
  }
}
