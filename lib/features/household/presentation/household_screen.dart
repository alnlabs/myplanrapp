import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../core/strings/app_strings.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../auth/data/auth_repository.dart';
import '../data/household_repository.dart';

class HouseholdScreen extends ConsumerStatefulWidget {
  const HouseholdScreen({super.key});

  @override
  ConsumerState<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends ConsumerState<HouseholdScreen> {
  final _emailController = TextEditingController();
  bool _inviting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final emailError = Validators.email(_emailController.text);
    if (emailError != null) {
      setState(() => _error = emailError);
      return;
    }
    setState(() {
      _inviting = true;
      _error = null;
    });
    try {
      final profile = await ref.read(userProfileProvider.future);
      final householdId = profile?.activeHouseholdId;
      if (householdId == null) return;
      await ref.read(householdRepositoryProvider).inviteMember(
            householdId,
            _emailController.text.trim(),
          );
      _emailController.clear();
      ref.invalidate(sentPendingInvitesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invite sent')),
        );
      }
    } catch (e) {
      setState(() => _error = ApiErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _inviting = false);
    }
  }

  Future<void> _leaveHousehold(String householdId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.leaveHousehold),
        content: const Text('You will lose access to this family\'s shared data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.leaveHousehold),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(householdRepositoryProvider).leaveHousehold(householdId);
      ref.invalidate(userProfileProvider);
      ref.invalidate(activeHouseholdProvider);
      ref.invalidate(householdMembersProvider);
      if (mounted) context.go('/household-setup');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorFormatter.format(e))),
        );
      }
    }
  }

  Future<void> _removeMember(String householdId, String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.removeMember),
        content: const Text('Remove this member from the family?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
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
      await ref
          .read(householdRepositoryProvider)
          .removeMember(householdId, userId);
      ref.invalidate(householdMembersProvider);
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
    final householdAsync = ref.watch(activeHouseholdProvider);
    final membersAsync = ref.watch(householdMembersProvider);
    final sentInvitesAsync = ref.watch(sentPendingInvitesProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.householdTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          householdAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(e.toString()),
            data: (household) => Card(
              child: ListTile(
                leading: const Icon(Icons.family_restroom_outlined),
                title: Text(household?.name ?? AppStrings.householdTitle),
                subtitle: const Text(AppStrings.members),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AsyncScreenBody(
            value: membersAsync,
            onRetry: () => ref.invalidate(householdMembersProvider),
            builder: (members) {
              final householdId =
                  ref.read(userProfileProvider).valueOrNull?.activeHouseholdId;
              final isOwner = members.any(
                (m) => m.userId == currentUserId && m.role == 'owner',
              );

              return Column(
                children: members.map((m) {
                  final isSelf = m.userId == currentUserId;
                  return Card(
                    child: ListTile(
                      title: Text(m.displayName ?? m.userId),
                      subtitle: Text(m.role),
                      trailing: isOwner && !isSelf && m.role != 'owner'
                          ? IconButton(
                              icon: const Icon(Icons.person_remove_outlined),
                              tooltip: AppStrings.removeMember,
                              onPressed: householdId == null
                                  ? null
                                  : () => _removeMember(householdId, m.userId),
                            )
                          : isSelf && !isOwner
                              ? TextButton(
                                  onPressed: householdId == null
                                      ? null
                                      : () => _leaveHousehold(householdId),
                                  child: const Text(AppStrings.leaveHousehold),
                                )
                              : null,
                    ),
                  );
                }).toList(),
              );
            },
          ),
          sentInvitesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (invites) {
              final members = membersAsync.valueOrNull ?? [];
              final isOwner = members.any(
                (m) => m.userId == currentUserId && m.role == 'owner',
              );
              if (!isOwner || invites.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.pendingInvites,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...invites.map(
                    (invite) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.mail_outline),
                        title: Text(invite['invited_email'] as String),
                        subtitle: const Text('Waiting to accept'),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          membersAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (members) {
              final isOwner = members.any(
                (m) => m.userId == currentUserId && m.role == 'owner',
              );
              if (!isOwner) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  AppTextField(
                    controller: _emailController,
                    label: AppStrings.inviteMember,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  LoadingButton(
                    label: AppStrings.inviteMember,
                    isLoading: _inviting,
                    onPressed: _invite,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
