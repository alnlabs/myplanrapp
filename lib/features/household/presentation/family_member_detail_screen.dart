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
import '../../../shared/widgets/loading_button.dart';
import '../../auth/data/auth_repository.dart';
import '../data/family_repository.dart';
import '../data/household_repository.dart';
import 'medicine_schedules_section.dart';
import 'member_avatar_picker.dart';
import 'member_role_actions.dart';
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

class _FamilyMemberDetailScreenState extends ConsumerState<FamilyMemberDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  bool _saving = false;
  String? _error;

  final _phone = TextEditingController();
  final _altPhone = TextEditingController();
  final _bloodGroup = TextEditingController();
  final _allergies = TextEditingController();
  final _medicines = TextEditingController();
  final _doctorName = TextEditingController();
  final _doctorPhone = TextEditingController();
  final _foodAllergies = TextEditingController();
  final _workPlace = TextEditingController();
  final _schoolName = TextEditingController();
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();
  final _emergencyRelation = TextEditingController();
  final _notes = TextEditingController();
  final _shirtSize = TextEditingController();
  final _pantsSize = TextEditingController();
  final _shoeSize = TextEditingController();
  final _displayName = TextEditingController();
  String? _dietaryPreference;
  Map<String, bool> _visibility = {
    MemberVisibilityKeys.phone: true,
    MemberVisibilityKeys.health: true,
    MemberVisibilityKeys.emergency: true,
  };
  bool _loaded = false;

  @override
  void dispose() {
    _tabs.dispose();
    _phone.dispose();
    _altPhone.dispose();
    _bloodGroup.dispose();
    _allergies.dispose();
    _medicines.dispose();
    _doctorName.dispose();
    _doctorPhone.dispose();
    _foodAllergies.dispose();
    _workPlace.dispose();
    _schoolName.dispose();
    _emergencyName.dispose();
    _emergencyPhone.dispose();
    _emergencyRelation.dispose();
    _notes.dispose();
    _shirtSize.dispose();
    _pantsSize.dispose();
    _shoeSize.dispose();
    _displayName.dispose();
    super.dispose();
  }

  void _loadProfileName(String? name) {
    if (!widget.profileMode || name == null) return;
    if (_displayName.text.isEmpty) {
      _displayName.text = name;
    }
  }

  void _loadDetails(FamilyMemberDetails? details) {
    if (_loaded || details == null) return;
    _phone.text = details.phone ?? '';
    _altPhone.text = details.altPhone ?? '';
    _bloodGroup.text = details.bloodGroup ?? '';
    _allergies.text = details.allergies ?? '';
    _medicines.text = details.medicines ?? '';
    _doctorName.text = details.doctorName ?? '';
    _doctorPhone.text = details.doctorPhone ?? '';
    _foodAllergies.text = details.foodAllergies ?? '';
    _workPlace.text = details.workPlace ?? '';
    _schoolName.text = details.schoolName ?? '';
    _emergencyName.text = details.emergencyContactName ?? '';
    _emergencyPhone.text = details.emergencyContactPhone ?? '';
    _emergencyRelation.text = details.emergencyContactRelation ?? '';
    _notes.text = details.notes ?? '';
    _shirtSize.text = details.clothingSizes[ClothingSizeKeys.shirt] ?? '';
    _pantsSize.text = details.clothingSizes[ClothingSizeKeys.pants] ?? '';
    _shoeSize.text = details.clothingSizes[ClothingSizeKeys.shoes] ?? '';
    _dietaryPreference = details.dietaryPreference;
    if (details.visibility.isNotEmpty) {
      _visibility = {
        for (final key in MemberVisibilityKeys.all)
          key: details.isVisible(key),
      };
    }
    _loaded = true;
  }

  FamilyMemberDetails _buildDetails(FamilyMember member, FamilyMemberDetails? existing) {
    return FamilyMemberDetails(
      familyMemberId: member.id,
      householdId: member.householdId,
      userId: member.userId,
      phone: _emptyToNull(_phone.text),
      altPhone: _emptyToNull(_altPhone.text),
      bloodGroup: _emptyToNull(_bloodGroup.text),
      allergies: _emptyToNull(_allergies.text),
      medicines: _emptyToNull(_medicines.text),
      doctorName: _emptyToNull(_doctorName.text),
      doctorPhone: _emptyToNull(_doctorPhone.text),
      dietaryPreference: _dietaryPreference,
      foodAllergies: _emptyToNull(_foodAllergies.text),
      workPlace: _emptyToNull(_workPlace.text),
      schoolName: _emptyToNull(_schoolName.text),
      emergencyContactName: _emptyToNull(_emergencyName.text),
      emergencyContactPhone: _emptyToNull(_emergencyPhone.text),
      emergencyContactRelation: _emptyToNull(_emergencyRelation.text),
      notes: _emptyToNull(_notes.text),
      dateOfBirth: existing?.dateOfBirth ?? member.dateOfBirth,
      avatarUrl: existing?.avatarUrl,
      clothingSizes: {
        if (_shirtSize.text.trim().isNotEmpty)
          ClothingSizeKeys.shirt: _shirtSize.text.trim(),
        if (_pantsSize.text.trim().isNotEmpty)
          ClothingSizeKeys.pants: _pantsSize.text.trim(),
        if (_shoeSize.text.trim().isNotEmpty)
          ClothingSizeKeys.shoes: _shoeSize.text.trim(),
      },
      visibility: _visibility,
    );
  }

  String? _emptyToNull(String value) =>
      value.trim().isEmpty ? null : value.trim();

  bool _isSectionPrivate(
    FamilyMemberDetails? details,
    bool canEdit,
    String key,
  ) {
    return !canEdit && details != null && !details.isVisible(key);
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

  Future<void> _save(FamilyMember member, FamilyMemberDetails? existing) async {
    if (widget.profileMode) {
      final nameError = Validators.required(_displayName.text);
      if (nameError != null) {
        setState(() => _error = nameError);
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.profileMode) {
        await ref
            .read(authRepositoryProvider)
            .updateDisplayName(_displayName.text.trim());
        ref.invalidate(userProfileProvider);
        ref.invalidate(familyRosterProvider);
        ref.invalidate(familyMemberProvider(member.id));
      }
      await ref.read(familyRepositoryProvider).upsertDetails(
            member.id,
            _buildDetails(member, existing),
          );
      ref.invalidate(familyMemberDetailsProvider(member.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.saved)),
        );
      }
    } catch (e) {
      setState(() => _error = ApiErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
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

  Future<void> _changeRole(
    FamilyMember member,
    String role,
  ) async {
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
    final profileAsync = ref.watch(userProfileProvider);
    final email = ref.watch(supabaseClientProvider).auth.currentUser?.email;

    profileAsync.whenData((profile) => _loadProfileName(profile?.displayName));

    return Scaffold(
      appBar: AppBar(
        title: widget.profileMode
            ? const Text(AppStrings.profileTitle)
            : memberAsync.when(
                data: (m) => Text(m?.listLabel ?? AppStrings.members),
                loading: () => const Text(AppStrings.members),
                error: (_, __) => const Text(AppStrings.members),
              ),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: AppStrings.tabOverview),
            Tab(text: AppStrings.tabHealth),
            Tab(text: AppStrings.tabEmergency),
          ],
        ),
      ),
      body: AsyncScreenBody(
        value: memberAsync,
        onRetry: () => ref.invalidate(familyMemberProvider(widget.memberId)),
        builder: (member) {
          if (member == null) {
            return const Center(child: Text(AppStrings.errorGeneric));
          }

          detailsAsync.whenData(_loadDetails);
          final details = detailsAsync.valueOrNull;
          final isSelf = member.userId == currentUserId;
          final members = ref.watch(householdMembersProvider).valueOrNull ?? [];
          final household = ref.watch(activeHouseholdProvider).valueOrNull;
          final isManager = members.any(
            (m) =>
                m.userId == currentUserId &&
                (m.role == 'owner' || m.role == 'co_owner'),
          );
          final isOwner = household?.ownerId == currentUserId ||
              members.any(
                (m) => m.userId == currentUserId && m.role == 'owner',
              );
          final membership = membershipForUser(members, member.userId);
          final managedByYou =
              !widget.profileMode &&
              member.isRosterOnly &&
              member.createdBy == currentUserId;
          final canEdit = widget.profileMode || isManager || isSelf || managedByYou;

          return Column(
            children: [
              if (managedByYou)
                const MaterialBanner(
                  content: Text(AppStrings.managedByYou),
                  leading: Icon(Icons.supervisor_account_outlined),
                  actions: [SizedBox.shrink()],
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _overviewTab(
                      member,
                      details,
                      isSelf,
                      isManager,
                      isOwner,
                      canEdit,
                      membership,
                      currentUserId,
                      email,
                    ),
                    _healthTab(member, details, canEdit),
                    _formTab(
                      member,
                      details,
                      [
                        AppTextField(
                          controller: _emergencyName,
                          label: AppStrings.emergencyContactName,
                          readOnly: !canEdit,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _emergencyPhone,
                          label: AppStrings.emergencyContactPhone,
                          keyboardType: TextInputType.phone,
                          readOnly: !canEdit,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _emergencyRelation,
                          label: AppStrings.emergencyContactRelation,
                          readOnly: !canEdit,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _notes,
                          label: AppStrings.notes,
                          maxLines: 4,
                          readOnly: !canEdit,
                        ),
                      ],
                      canEdit: canEdit,
                      isPrivate: _isSectionPrivate(
                        details,
                        canEdit,
                        MemberVisibilityKeys.emergency,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _overviewTab(
    FamilyMember member,
    FamilyMemberDetails? details,
    bool isSelf,
    bool isManager,
    bool isOwner,
    bool canEdit,
    HouseholdMember? membership,
    String? currentUserId,
    String? email,
  ) {
    final phonePrivate =
        _isSectionPrivate(details, canEdit, MemberVisibilityKeys.phone);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.profileMode) ...[
          Text(
            AppStrings.accountInfo,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          if (email != null) _infoRow(AppStrings.email, email),
          const SizedBox(height: 8),
          AppTextField(
            controller: _displayName,
            label: AppStrings.displayName,
            readOnly: !canEdit,
          ),
          const SizedBox(height: 20),
        ],
        MemberAvatarPicker(
          familyMemberId: member.id,
          householdId: member.householdId,
          displayName: member.listLabel,
          avatarPath: details?.avatarUrl,
          canEdit: canEdit,
          existingDetails: details ?? FamilyMemberDetails(
            familyMemberId: member.id,
            householdId: member.householdId,
            userId: member.userId,
          ),
        ),
        const SizedBox(height: 16),
        if (!widget.profileMode) ...[
          _infoRow(AppStrings.relationship, member.relationshipLabel),
          _infoRow(
            AppStrings.memberType,
            member.isAppMember ? AppStrings.appMember : AppStrings.profileOnly,
          ),
        ],
        if (!widget.profileMode && membership != null)
          _infoRow(AppStrings.appRole, roleLabel(membership.role)),
        if (!widget.profileMode &&
            isOwner &&
            member.isAppMember &&
            membership != null &&
            canChangeRole(
              isOwner: isOwner,
              targetUserId: member.userId,
              currentUserId: currentUserId,
              targetRole: membership.role,
            ))
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: MemberRoleActions(
              currentRole: membership.role,
              onMakeCoOwner: () => _changeRole(member, 'co_owner'),
              onMakeMember: () => _changeRole(member, 'member'),
            ),
          ),
        if (!widget.profileMode &&
            isOwner &&
            member.isRosterOnly &&
            !member.isPendingInvite)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              AppStrings.coOwnerRequiresApp,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
        if (!widget.profileMode && isOwner && member.relationship != 'self')
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => member.isAppMember
                  ? _convertToProfileOnly(member)
                  : _convertToApp(member),
              icon: Icon(
                member.isAppMember
                    ? Icons.person_outline
                    : Icons.mail_outline,
              ),
              label: Text(
                member.isAppMember
                    ? AppStrings.makeProfileOnly
                    : AppStrings.inviteToApp,
              ),
            ),
          ),
        if (!widget.profileMode && member.isPendingInvite)
          _infoRow(AppStrings.status, AppStrings.pendingInvite),
        if (!widget.profileMode && member.invitedEmail != null)
          _infoRow(AppStrings.email, member.invitedEmail!),
        if (!phonePrivate &&
            (details?.phone != null || member.phone != null))
          _infoRow(AppStrings.phone, details?.phone ?? member.phone!),
        if (details?.dateOfBirth != null || member.dateOfBirth != null)
          _infoRow(
            AppStrings.dateOfBirth,
            Formatters.date(details?.dateOfBirth ?? member.dateOfBirth!),
          ),
        if (details?.workPlace != null)
          _infoRow(AppStrings.workPlace, details!.workPlace!),
        if (details?.schoolName != null)
          _infoRow(AppStrings.schoolName, details!.schoolName!),
        const SizedBox(height: 16),
        if (phonePrivate) ...[
          _privateBanner(),
        ] else ...[
          AppTextField(
            controller: _phone,
            label: AppStrings.phone,
            readOnly: !canEdit,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _altPhone,
            label: AppStrings.altPhone,
            readOnly: !canEdit,
          ),
        ],
        const SizedBox(height: 12),
        AppTextField(
          controller: _workPlace,
          label: AppStrings.workPlace,
          readOnly: !canEdit,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _schoolName,
          label: AppStrings.schoolName,
          readOnly: !canEdit,
        ),
        const SizedBox(height: 24),
        Text(
          AppStrings.clothingSizes,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        AppTextField(
          controller: _shirtSize,
          label: AppStrings.shirtSize,
          readOnly: !canEdit,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _pantsSize,
          label: AppStrings.pantsSize,
          readOnly: !canEdit,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _shoeSize,
          label: AppStrings.shoeSize,
          readOnly: !canEdit,
        ),
        if (canEdit) ...[
          const SizedBox(height: 24),
          Text(
            AppStrings.fieldVisibility,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.visibilityPhone),
            value: _visibility[MemberVisibilityKeys.phone] ?? true,
            onChanged: (v) => setState(
              () => _visibility[MemberVisibilityKeys.phone] = v,
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.visibilityHealth),
            value: _visibility[MemberVisibilityKeys.health] ?? true,
            onChanged: (v) => setState(
              () => _visibility[MemberVisibilityKeys.health] = v,
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.visibilityEmergency),
            value: _visibility[MemberVisibilityKeys.emergency] ?? true,
            onChanged: (v) => setState(
              () => _visibility[MemberVisibilityKeys.emergency] = v,
            ),
          ),
        ],
        if (canEdit) ...[
          const SizedBox(height: 16),
          if (_error != null)
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 8),
          LoadingButton(
            label: AppStrings.save,
            isLoading: _saving,
            onPressed: () => _save(member, details),
          ),
        ],
        if (isSelf && !isOwner && !widget.profileMode) ...[
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => _leave(member.householdId),
            child: const Text(AppStrings.leaveHousehold),
          ),
        ],
        if (!widget.profileMode && isManager && member.relationship != 'self') ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _remove(member),
            child: Text(
              AppStrings.removeMember,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ],
    );
  }

  Widget _healthTab(
    FamilyMember member,
    FamilyMemberDetails? details,
    bool canEdit,
  ) {
    final healthPrivate =
        _isSectionPrivate(details, canEdit, MemberVisibilityKeys.health);

    if (healthPrivate) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [_privateBanner()],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppTextField(
          controller: _bloodGroup,
          label: AppStrings.bloodGroup,
          readOnly: !canEdit,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _allergies,
          label: AppStrings.allergies,
          maxLines: 2,
          readOnly: !canEdit,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _medicines,
          label: AppStrings.medicines,
          maxLines: 2,
          readOnly: !canEdit,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _doctorName,
          label: AppStrings.doctorName,
          readOnly: !canEdit,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _doctorPhone,
          label: AppStrings.doctorPhone,
          keyboardType: TextInputType.phone,
          readOnly: !canEdit,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _dietaryPreference,
          decoration: const InputDecoration(labelText: AppStrings.diet),
          items: const [
            DropdownMenuItem(value: 'veg', child: Text('Vegetarian')),
            DropdownMenuItem(value: 'non_veg', child: Text('Non-vegetarian')),
            DropdownMenuItem(value: 'vegan', child: Text('Vegan')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
          onChanged: canEdit ? (v) => setState(() => _dietaryPreference = v) : null,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _foodAllergies,
          label: AppStrings.foodAllergies,
          maxLines: 2,
          readOnly: !canEdit,
        ),
        const SizedBox(height: 24),
        MedicineSchedulesSection(
          familyMemberId: member.id,
          householdId: member.householdId,
          canEdit: canEdit,
        ),
        if (canEdit) ...[
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 16),
          LoadingButton(
            label: AppStrings.save,
            isLoading: _saving,
            onPressed: () => _save(member, details),
          ),
        ],
      ],
    );
  }

  Widget _formTab(
    FamilyMember member,
    FamilyMemberDetails? details,
    List<Widget> fields, {
    required bool canEdit,
    required bool isPrivate,
  }) {
    if (isPrivate) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [_privateBanner()],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...fields,
        if (canEdit) ...[
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 16),
          LoadingButton(
            label: AppStrings.save,
            isLoading: _saving,
            onPressed: () => _save(member, details),
          ),
        ],
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
