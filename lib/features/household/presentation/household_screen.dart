import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../core/strings/app_strings.dart';
import '../../../shared/models/family_member.dart';
import '../../../shared/models/household.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../../auth/data/auth_repository.dart';
import '../data/family_repository.dart';
import '../data/household_repository.dart';
import 'add_family_member_screen.dart';
import 'family_member_detail_screen.dart';
import 'household_features_screen.dart';
import 'member_role_actions.dart';
import 'member_role_helpers.dart';
import 'member_avatar_circle.dart';

class HouseholdScreen extends ConsumerWidget {
  const HouseholdScreen({super.key});

  Future<void> _openAddMember(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AddFamilyMemberScreen(),
      ),
    );
  }

  Future<void> _changeRole(
    BuildContext context,
    WidgetRef ref, {
    required String householdId,
    required String userId,
    required String role,
  }) async {
    try {
      await ref
          .read(householdRepositoryProvider)
          .setMemberRole(householdId, userId, role);
      ref.invalidate(householdMembersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.roleUpdated)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorFormatter.format(e))),
        );
      }
    }
  }

  Future<void> _cancelInvite(
    BuildContext context,
    WidgetRef ref,
    String inviteId,
  ) async {
    try {
      await ref.read(householdRepositoryProvider).cancelInvite(inviteId);
      ref.invalidate(sentPendingInvitesProvider);
      ref.invalidate(familyRosterProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.inviteRevoked)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorFormatter.format(e))),
        );
      }
    }
  }

  bool _isOwner({
    required Household? household,
    required List<HouseholdMember> members,
    required String? currentUserId,
  }) {
    if (currentUserId == null) return false;
    if (household?.ownerId == currentUserId) return true;
    return members.any(
      (m) => m.userId == currentUserId && m.role == 'owner',
    );
  }

  bool _isManager({
    required Household? household,
    required List<HouseholdMember> members,
    required String? currentUserId,
  }) {
    if (currentUserId == null) return false;
    if (household?.ownerId == currentUserId) return true;
    return members.any(
      (m) =>
          m.userId == currentUserId &&
          (m.role == 'owner' || m.role == 'co_owner'),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final householdAsync = ref.watch(activeHouseholdProvider);
    final rosterAsync = ref.watch(familyRosterProvider);
    final membersAsync = ref.watch(householdMembersProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    final hasHousehold = profileAsync.valueOrNull?.hasHousehold ?? false;
    if (profileAsync.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!hasHousehold) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.householdTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.family_restroom_outlined,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  AppStrings.noHousehold,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.noHouseholdFamilyHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => context.go('/household-setup'),
                  icon: const Icon(Icons.add_home_outlined),
                  label: const Text(AppStrings.createFamilyToContinue),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final household = householdAsync.valueOrNull;
    final members = membersAsync.valueOrNull ?? const <HouseholdMember>[];
    final isOwner = _isOwner(
      household: household,
      members: members,
      currentUserId: currentUserId,
    );
    final isManager = _isManager(
      household: household,
      members: members,
      currentUserId: currentUserId,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.householdTitle),
        actions: [
          if (isOwner)
            IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const HouseholdFeaturesScreen(),
                ),
              ),
              icon: const Icon(Icons.tune_outlined),
              tooltip: AppStrings.featureSettings,
            ),
          if (isManager)
            IconButton(
              onPressed: () => _openAddMember(context),
              icon: const Icon(Icons.person_add_outlined),
              tooltip: AppStrings.addFamilyMember,
            ),
        ],
      ),
      floatingActionButton: isManager
          ? FloatingActionButton.extended(
              onPressed: () => _openAddMember(context),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text(AppStrings.addMember),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeHouseholdProvider);
          ref.invalidate(familyRosterProvider);
          ref.invalidate(householdMembersProvider);
          ref.invalidate(sentPendingInvitesProvider);
          await Future.wait([
            ref.read(activeHouseholdProvider.future),
            ref.read(familyRosterProvider.future),
            ref.read(householdMembersProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            _HouseholdHeaderCard(
              householdAsync: householdAsync,
              rosterAsync: rosterAsync,
              isManager: isManager,
              onAdd: () => _openAddMember(context),
            ),
            if (isOwner) ...[
              const SizedBox(height: 24),
              Text(
                AppStrings.membersAndRoles,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.membersAndRolesHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              if (members.where((m) => m.role != 'owner').isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    AppStrings.noOtherAppMembers,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ),
              ...members.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RoleTile(
                    member: m,
                    isSelf: m.userId == currentUserId,
                    currentUserId: currentUserId,
                    canManage: isOwner,
                    householdId: household?.id,
                    onMakeCoOwner: (householdId) => _changeRole(
                      context,
                      ref,
                      householdId: householdId,
                      userId: m.userId,
                      role: 'co_owner',
                    ),
                    onMakeMember: (householdId) => _changeRole(
                      context,
                      ref,
                      householdId: householdId,
                      userId: m.userId,
                      role: 'member',
                    ),
                  ),
                ),
              ),
            ],
            if (isManager) ...[
              const SizedBox(height: 24),
              Text(
                AppStrings.pendingInvites,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, _) {
                  final invitesAsync = ref.watch(sentPendingInvitesProvider);
                  return invitesAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text(ApiErrorFormatter.format(e)),
                    data: (invites) {
                      if (invites.isEmpty) {
                        return Text(
                          AppStrings.noPendingInvites,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        );
                      }
                      return Column(
                        children: invites.map((invite) {
                          final email =
                              invite['invited_email'] as String? ?? '';
                          final id = invite['id'] as String;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .tertiaryContainer,
                                  child: Icon(
                                    Icons.mark_email_unread_outlined,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onTertiaryContainer,
                                  ),
                                ),
                                title: Text(email),
                                subtitle: const Text(AppStrings.pendingInvite),
                                trailing: IconButton(
                                  icon: const Icon(Icons.cancel_outlined),
                                  tooltip: AppStrings.revokeInvite,
                                  onPressed: () =>
                                      _cancelInvite(context, ref, id),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  );
                },
              ),
            ],
            const SizedBox(height: 24),
            Text(
              AppStrings.householdTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            AsyncScreenBody(
              value: rosterAsync,
              onRetry: () => ref.invalidate(familyRosterProvider),
              isEmpty: (roster) => roster.isEmpty,
              emptyTitle: AppStrings.emptyFamilyRoster,
              emptySubtitle: AppStrings.emptyFamilyRosterHint,
              emptyActionLabel:
                  isManager ? AppStrings.addFamilyMember : null,
              onEmptyAction:
                  isManager ? () => _openAddMember(context) : null,
              builder: (roster) {
                return Column(
                  children: roster
                      .map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _MemberTile(
                            member: m,
                            members: members,
                            isOwner: isOwner,
                            currentUserId: currentUserId,
                            householdId: household?.id,
                            onChangeRole: (userId, role) => _changeRole(
                              context,
                              ref,
                              householdId: household!.id,
                              userId: userId,
                              role: role,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HouseholdHeaderCard extends ConsumerWidget {
  const _HouseholdHeaderCard({
    required this.householdAsync,
    required this.rosterAsync,
    required this.isManager,
    required this.onAdd,
  });

  final AsyncValue<Household?> householdAsync;
  final AsyncValue<List<FamilyMember>> rosterAsync;
  final bool isManager;
  final VoidCallback onAdd;

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    Household household,
  ) async {
    final controller = TextEditingController(text: household.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.editFamilyName),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: AppStrings.householdName),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty || newName == household.name) return;

    try {
      await ref
          .read(householdRepositoryProvider)
          .renameHousehold(household.id, newName);
      ref.invalidate(activeHouseholdProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.familyNameUpdated)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final rosterCount = rosterAsync.valueOrNull?.length ?? 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.family_restroom_outlined,
                    color: colorScheme.onPrimaryContainer,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: householdAsync.when(
                    loading: () => const Text('...'),
                    error: (e, _) => Text(e.toString()),
                    data: (household) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          household?.name ?? AppStrings.householdTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$rosterCount ${AppStrings.familyMemberCount}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isManager && householdAsync.valueOrNull != null)
                  IconButton(
                    tooltip: AppStrings.editFamilyName,
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () =>
                        _editName(context, ref, householdAsync.value!),
                  ),
              ],
            ),
            if (isManager) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text(AppStrings.addFamilyMember),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.member,
    required this.isSelf,
    required this.currentUserId,
    required this.canManage,
    required this.householdId,
    required this.onMakeCoOwner,
    required this.onMakeMember,
  });

  final HouseholdMember member;
  final bool isSelf;
  final String? currentUserId;
  final bool canManage;
  final String? householdId;
  final void Function(String householdId) onMakeCoOwner;
  final void Function(String householdId) onMakeMember;

  @override
  Widget build(BuildContext context) {
    final name = member.listLabel;
    final showActions = canManage &&
        householdId != null &&
        canChangeRole(
          isOwner: canManage,
          targetUserId: member.userId,
          currentUserId: currentUserId,
          targetRole: member.role,
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
              ),
              title: Text(isSelf ? '$name (${AppStrings.you})' : name),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: MemberRoleBadge(role: member.role),
              ),
            ),
            if (showActions)
              MemberRoleActions(
                currentRole: member.role,
                onMakeCoOwner: () => onMakeCoOwner(householdId!),
                onMakeMember: () => onMakeMember(householdId!),
              ),
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({
    required this.member,
    required this.members,
    required this.isOwner,
    required this.currentUserId,
    required this.householdId,
    required this.onChangeRole,
  });

  final FamilyMember member;
  final List<HouseholdMember> members;
  final bool isOwner;
  final String? currentUserId;
  final String? householdId;
  final void Function(String userId, String role) onChangeRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = membershipForUser(members, member.userId);
    final appRole = membership?.role;
    final showRoleActions = member.isAppMember &&
        householdId != null &&
        appRole != null &&
        canChangeRole(
          isOwner: isOwner,
          targetUserId: member.userId,
          currentUserId: currentUserId,
          targetRole: appRole,
        );

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => FamilyMemberDetailScreen(memberId: member.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MemberAvatarCircle(
                    displayName: member.listLabel,
                    avatarPath: member.avatarUrl,
                    radius: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.listLabel,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _Badge(label: member.relationshipLabel),
                            _Badge(
                              label: member.isAppMember
                                  ? AppStrings.appMember
                                  : AppStrings.profileOnly,
                              muted: true,
                            ),
                            if (appRole != null)
                              MemberRoleBadge(role: appRole),
                            if (member.isPendingInvite)
                              const _Badge(
                                label: AppStrings.pendingInvite,
                                highlight: true,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (isOwner && member.isRosterOnly && !member.isPendingInvite) ...[
                const SizedBox(height: 8),
                Text(
                  AppStrings.coOwnerRequiresApp,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
              if (showRoleActions) ...[
                const SizedBox(height: 8),
                MemberRoleActions(
                  compact: true,
                  currentRole: appRole,
                  onMakeCoOwner: () => onChangeRole(member.userId!, 'co_owner'),
                  onMakeMember: () => onChangeRole(member.userId!, 'member'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    this.muted = false,
    this.highlight = false,
  });

  final String label;
  final bool muted;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = highlight
        ? colorScheme.tertiaryContainer
        : muted
            ? colorScheme.surfaceContainerHighest
            : colorScheme.primaryContainer;
    final fg = highlight
        ? colorScheme.onTertiaryContainer
        : muted
            ? colorScheme.onSurfaceVariant
            : colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
