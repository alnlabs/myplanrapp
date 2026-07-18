import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../core/strings/app_strings.dart';
import '../../../shared/models/family_member.dart';
import '../../../shared/models/household.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../data/family_repository.dart';
import '../data/household_repository.dart';
import 'family_member_edit_screen.dart';
import 'medicine_schedules_section.dart';
import 'member_avatar_picker.dart';
import 'member_income_section.dart';
import 'member_role_actions.dart';
import 'recurring_income_section.dart';
import 'member_role_helpers.dart';

class FamilyMemberDetailScreen extends ConsumerStatefulWidget {
  const FamilyMemberDetailScreen({
    super.key,
    required this.memberId,
    this.profileMode = false,
  });

  final String memberId;
  final bool profileMode;

  @override
  ConsumerState<FamilyMemberDetailScreen> createState() =>
      _FamilyMemberDetailScreenState();
}

class _FamilyMemberDetailScreenState
    extends ConsumerState<FamilyMemberDetailScreen> {
  bool _isSectionPrivate(
    FamilyMemberDetails? details,
    bool canEdit,
    String key,
  ) {
    return !canEdit && details != null && !details.isVisible(key);
  }

  void _openEdit() {
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => FamilyMemberEditScreen(
          memberId: widget.memberId,
          profileMode: widget.profileMode,
        ),
      ),
    );
  }

  Future<void> _remove(FamilyMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.removeMember),
        content: Text('Remove ${member.listLabel} from the family?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.removeMember),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(familyRepositoryProvider).removeRosterMember(member.id);
      ref.invalidate(familyRosterProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorFormatter.format(e))),
        );
      }
    }
  }

  Future<void> _convertToApp(FamilyMember member) async {
    final controller = TextEditingController(text: member.invitedEmail ?? '');
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.inviteToAppTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppStrings.inviteToAppEmailHint),
            const SizedBox(height: 12),
            AppTextField(
              controller: controller,
              label: AppStrings.email,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text(AppStrings.inviteToApp),
          ),
        ],
      ),
    );
    if (email == null) return;
    final error = Validators.email(email);
    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }
    await _runTypeChange(
      () => ref.read(familyRepositoryProvider).convertToAppMember(
            familyMemberId: member.id,
            email: email,
          ),
      member.id,
    );
  }

  Future<void> _convertToProfileOnly(FamilyMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.makeProfileOnly),
        content: const Text(AppStrings.makeProfileOnlyConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.makeProfileOnly),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runTypeChange(
      () => ref.read(familyRepositoryProvider).convertToProfileOnly(member.id),
      member.id,
    );
  }

  Future<void> _changeRole(FamilyMember member, String role) async {
    final userId = member.userId;
    if (userId == null) return;
    try {
      await ref.read(householdRepositoryProvider).setMemberRole(
            member.householdId,
            userId,
            role,
          );
      ref.invalidate(householdMembersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.roleUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorFormatter.format(e))),
        );
      }
    }
  }

  Future<void> _runTypeChange(
    Future<void> Function() action,
    String memberId,
  ) async {
    try {
      await action();
      ref.invalidate(familyMemberProvider(memberId));
      ref.invalidate(familyRosterProvider);
      ref.invalidate(sentPendingInvitesProvider);
      ref.invalidate(householdMembersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.memberTypeChanged)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorFormatter.format(e))),
        );
      }
    }
  }

  Future<void> _leave(String householdId) async {
    try {
      await ref.read(householdRepositoryProvider).leaveHousehold(householdId);
      ref.invalidate(familyRosterProvider);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorFormatter.format(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberAsync = ref.watch(familyMemberProvider(widget.memberId));
    final detailsAsync = ref.watch(familyMemberDetailsProvider(widget.memberId));
    final currentUserId = ref.watch(currentUserIdProvider);
    final email = ref.watch(supabaseClientProvider).auth.currentUser?.email;
    final members = ref.watch(householdMembersProvider).valueOrNull ?? [];
    final household = ref.watch(activeHouseholdProvider).valueOrNull;

    final headMember = memberAsync.valueOrNull;
    final canEditAppBar = _canEdit(headMember, members, household, currentUserId);

    return Scaffold(
      appBar: AppBar(
        title: widget.profileMode
            ? const Text(AppStrings.profileTitle)
            : Text(headMember?.listLabel ?? AppStrings.members),
        actions: [
          if (canEditAppBar)
            IconButton(
              onPressed: _openEdit,
              icon: const Icon(Icons.edit_outlined),
              tooltip: widget.profileMode
                  ? AppStrings.editProfile
                  : AppStrings.editDetails,
            ),
        ],
      ),
      body: AsyncScreenBody(
        value: memberAsync,
        onRetry: () => ref.invalidate(familyMemberProvider(widget.memberId)),
        builder: (member) {
          if (member == null) {
            return const Center(child: Text(AppStrings.errorGeneric));
          }

          final details = detailsAsync.valueOrNull;
          final isSelf = member.userId == currentUserId;
          final isManager = _isManager(members, currentUserId);
          final isOwner = _isOwner(members, household, currentUserId);
          final membership = membershipForUser(members, member.userId);
          final managedByYou = !widget.profileMode &&
              member.isRosterOnly &&
              member.createdBy == currentUserId;
          final canEdit = _canEdit(member, members, household, currentUserId);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: _buildContent(
              member: member,
              details: details,
              email: email,
              isSelf: isSelf,
              isManager: isManager,
              isOwner: isOwner,
              membership: membership,
              managedByYou: managedByYou,
              canEdit: canEdit,
              currentUserId: currentUserId,
            ),
          );
        },
      ),
      floatingActionButton: canEditAppBar
          ? FloatingActionButton.extended(
              onPressed: _openEdit,
              icon: const Icon(Icons.edit_outlined),
              label: Text(
                widget.profileMode
                    ? AppStrings.editProfile
                    : AppStrings.editDetails,
              ),
            )
          : null,
    );
  }

  bool _isManager(List<HouseholdMember> members, String? currentUserId) {
    return members.any(
      (m) =>
          m.userId == currentUserId &&
          (m.role == 'owner' || m.role == 'co_owner'),
    );
  }

  bool _isOwner(
    List<HouseholdMember> members,
    Household? household,
    String? currentUserId,
  ) {
    return household?.ownerId == currentUserId ||
        members.any((m) => m.userId == currentUserId && m.role == 'owner');
  }

  bool _canEdit(
    FamilyMember? member,
    List<HouseholdMember> members,
    Household? household,
    String? currentUserId,
  ) {
    if (member == null) return widget.profileMode;
    final isSelf = member.userId == currentUserId;
    final managedByYou = !widget.profileMode &&
        member.isRosterOnly &&
        member.createdBy == currentUserId;
    return widget.profileMode ||
        _isManager(members, currentUserId) ||
        isSelf ||
        managedByYou;
  }

  List<Widget> _buildContent({
    required FamilyMember member,
    required FamilyMemberDetails? details,
    required String? email,
    required bool isSelf,
    required bool isManager,
    required bool isOwner,
    required HouseholdMember? membership,
    required bool managedByYou,
    required bool canEdit,
    required String? currentUserId,
  }) {
    final phonePrivate =
        _isSectionPrivate(details, canEdit, MemberVisibilityKeys.phone);
    final healthPrivate =
        _isSectionPrivate(details, canEdit, MemberVisibilityKeys.health);
    final emergencyPrivate =
        _isSectionPrivate(details, canEdit, MemberVisibilityKeys.emergency);

    final children = <Widget>[];
    var addedDetailSection = false;

    void addSection(String title, List<Widget?> rows) {
      final present = rows.whereType<Widget>().toList();
      if (present.isEmpty) return;
      children.add(_sectionTitle(title));
      children.addAll(present);
      children.add(const SizedBox(height: 20));
    }

    // Header
    children.add(
      _header(
        member: member,
        details: details,
        subtitle: widget.profileMode ? email : member.relationshipLabel,
        membership: widget.profileMode ? null : membership,
      ),
    );
    children.add(const SizedBox(height: 24));

    if (managedByYou) {
      children.add(
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.supervisor_account_outlined),
                SizedBox(width: 12),
                Expanded(child: Text(AppStrings.managedByYou)),
              ],
            ),
          ),
        ),
      );
      children.add(const SizedBox(height: 16));
    }

    // Member meta (family members only)
    if (!widget.profileMode) {
      addSection(AppStrings.tabOverview, [
        _valueRow(
          AppStrings.memberType,
          member.isAppMember ? AppStrings.appMember : AppStrings.profileOnly,
        ),
        if (membership != null)
          _valueRow(AppStrings.appRole, roleLabel(membership.role)),
        if (member.isPendingInvite)
          _valueRow(AppStrings.status, AppStrings.pendingInvite),
        if (member.invitedEmail != null)
          _valueRow(AppStrings.email, member.invitedEmail!),
      ]);
    } else if (email != null) {
      addSection(AppStrings.accountInfo, [
        _valueRow(AppStrings.email, email),
      ]);
    }

    // Contact
    if (phonePrivate) {
      addSection(AppStrings.sectionContact, [_privateBanner()]);
    } else {
      final contactRows = [
        _valueRow(AppStrings.phone, details?.phone ?? member.phone),
        _valueRow(AppStrings.altPhone, details?.altPhone),
      ];
      if (contactRows.whereType<Widget>().isNotEmpty) addedDetailSection = true;
      addSection(AppStrings.sectionContact, contactRows);
    }

    // Basics
    final dob = details?.dateOfBirth ?? member.dateOfBirth;
    final basicsRows = [
      if (dob != null) _valueRow(AppStrings.dateOfBirth, Formatters.date(dob)),
      _valueRow(AppStrings.workPlace, details?.workPlace),
      _valueRow(AppStrings.schoolName, details?.schoolName),
    ];
    if (basicsRows.whereType<Widget>().isNotEmpty) addedDetailSection = true;
    addSection(AppStrings.sectionWorkSchool, basicsRows);

    // Health
    if (healthPrivate) {
      addSection(AppStrings.tabHealth, [_privateBanner()]);
    } else {
      final healthRows = [
        _valueRow(AppStrings.bloodGroup, details?.bloodGroup),
        _valueRow(AppStrings.allergies, details?.allergies),
        _valueRow(AppStrings.medicines, details?.medicines),
        _valueRow(AppStrings.doctorName, details?.doctorName),
        _valueRow(AppStrings.doctorPhone, details?.doctorPhone),
        _valueRow(AppStrings.diet, _dietLabel(details?.dietaryPreference)),
        _valueRow(AppStrings.foodAllergies, details?.foodAllergies),
      ];
      if (healthRows.whereType<Widget>().isNotEmpty) addedDetailSection = true;
      addSection(AppStrings.tabHealth, healthRows);
    }

    // Medicine schedules (family members only)
    if (!widget.profileMode) {
      children.add(
        MedicineSchedulesSection(
          familyMemberId: member.id,
          householdId: member.householdId,
          canEdit: canEdit,
        ),
      );
      children.add(const SizedBox(height: 20));
    }

    // Emergency
    if (emergencyPrivate) {
      addSection(AppStrings.tabEmergency, [_privateBanner()]);
    } else {
      final emergencyRows = [
        _valueRow(
          AppStrings.emergencyContactName,
          details?.emergencyContactName,
        ),
        _valueRow(
          AppStrings.emergencyContactPhone,
          details?.emergencyContactPhone,
        ),
        _valueRow(
          AppStrings.emergencyContactRelation,
          details?.emergencyContactRelation,
        ),
        _valueRow(AppStrings.notes, details?.notes),
      ];
      if (emergencyRows.whereType<Widget>().isNotEmpty) {
        addedDetailSection = true;
      }
      addSection(AppStrings.tabEmergency, emergencyRows);
    }

    // Clothing sizes
    final sizeRows = [
      _valueRow(
        AppStrings.shirtSize,
        details?.clothingSizes[ClothingSizeKeys.shirt],
      ),
      _valueRow(
        AppStrings.pantsSize,
        details?.clothingSizes[ClothingSizeKeys.pants],
      ),
      _valueRow(
        AppStrings.shoeSize,
        details?.clothingSizes[ClothingSizeKeys.shoes],
      ),
    ];
    if (sizeRows.whereType<Widget>().isNotEmpty) addedDetailSection = true;
    addSection(AppStrings.clothingSizes, sizeRows);

    // Income (family members only)
    if (!widget.profileMode) {
      children.add(
        MemberIncomeSection(familyMemberId: member.id, canEdit: canEdit),
      );
      children.add(const SizedBox(height: 12));
      children.add(
        RecurringIncomeSection(
          familyMemberId: member.id,
          householdId: member.householdId,
          canEdit: canEdit,
        ),
      );
      children.add(const SizedBox(height: 20));
    }

    // Empty hint
    if (!addedDetailSection && canEdit) {
      children.add(
        Text(
          AppStrings.profileEmptyHint,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
      children.add(const SizedBox(height: 20));
    }

    // Management actions (family members only)
    children.addAll(
      _managementActions(
        member: member,
        membership: membership,
        isSelf: isSelf,
        isManager: isManager,
        isOwner: isOwner,
        currentUserId: currentUserId,
      ),
    );

    // Bottom spacing so the FAB doesn't cover content
    children.add(const SizedBox(height: 80));
    return children;
  }

  List<Widget> _managementActions({
    required FamilyMember member,
    required HouseholdMember? membership,
    required bool isSelf,
    required bool isManager,
    required bool isOwner,
    required String? currentUserId,
  }) {
    if (widget.profileMode) return const [];
    final widgets = <Widget>[];

    if (isOwner &&
        member.isAppMember &&
        membership != null &&
        canChangeRole(
          isOwner: isOwner,
          targetUserId: member.userId,
          currentUserId: currentUserId,
          targetRole: membership.role,
        )) {
      widgets.add(
        Align(
          alignment: Alignment.centerLeft,
          child: MemberRoleActions(
            currentRole: membership.role,
            onMakeCoOwner: () => _changeRole(member, 'co_owner'),
            onMakeMember: () => _changeRole(member, 'member'),
          ),
        ),
      );
      widgets.add(const SizedBox(height: 8));
    }

    if (isOwner && member.isRosterOnly && !member.isPendingInvite) {
      widgets.add(
        Text(
          AppStrings.coOwnerRequiresApp,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      );
      widgets.add(const SizedBox(height: 8));
    }

    if (isOwner && member.relationship != 'self') {
      widgets.add(
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => member.isAppMember
                ? _convertToProfileOnly(member)
                : _convertToApp(member),
            icon: Icon(
              member.isAppMember ? Icons.person_outline : Icons.mail_outline,
            ),
            label: Text(
              member.isAppMember
                  ? AppStrings.makeProfileOnly
                  : AppStrings.inviteToApp,
            ),
          ),
        ),
      );
    }

    if (isSelf && !isOwner) {
      widgets.add(const SizedBox(height: 8));
      widgets.add(
        OutlinedButton(
          onPressed: () => _leave(member.householdId),
          child: const Text(AppStrings.leaveHousehold),
        ),
      );
    }

    if (isManager && member.relationship != 'self') {
      widgets.add(const SizedBox(height: 8));
      widgets.add(
        TextButton(
          onPressed: () => _remove(member),
          child: Text(
            AppStrings.removeMember,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _header({
    required FamilyMember member,
    required FamilyMemberDetails? details,
    required String? subtitle,
    required HouseholdMember? membership,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        children: [
          MemberAvatarPicker(
            familyMemberId: member.id,
            householdId: member.householdId,
            displayName: member.listLabel,
            avatarPath: details?.avatarUrl,
            canEdit: false,
            existingDetails: details,
          ),
          const SizedBox(height: 12),
          Text(
            member.listLabel,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (membership != null) ...[
            const SizedBox(height: 8),
            MemberRoleBadge(role: membership.role),
          ],
        ],
      ),
    );
  }

  Widget _privateBanner() {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppStrings.sectionPrivate,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget? _valueRow(String label, String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  String _dietLabel(String? value) {
    return switch (value) {
      'veg' => 'Vegetarian',
      'non_veg' => 'Non-vegetarian',
      'vegan' => 'Vegan',
      'other' => 'Other',
      _ => '',
    };
  }
}
