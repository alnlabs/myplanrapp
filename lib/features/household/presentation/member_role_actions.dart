import 'package:flutter/material.dart';

import '../../../core/strings/app_strings.dart';
import 'member_role_helpers.dart';

class MemberRoleActions extends StatelessWidget {
  const MemberRoleActions({
    super.key,
    required this.currentRole,
    required this.onMakeCoOwner,
    required this.onMakeMember,
    this.compact = false,
  });

  final String currentRole;
  final VoidCallback onMakeCoOwner;
  final VoidCallback onMakeMember;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (currentRole == 'co_owner') {
      return compact
          ? TextButton.icon(
              onPressed: onMakeMember,
              icon: const Icon(Icons.person_outline, size: 18),
              label: const Text(AppStrings.removeCoOwner),
            )
          : OutlinedButton.icon(
              onPressed: onMakeMember,
              icon: const Icon(Icons.person_outline),
              label: const Text(AppStrings.removeCoOwner),
            );
    }

    return compact
        ? FilledButton.tonalIcon(
            onPressed: onMakeCoOwner,
            icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
            label: const Text(AppStrings.makeCoOwner),
          )
        : FilledButton.tonalIcon(
            onPressed: onMakeCoOwner,
            icon: const Icon(Icons.admin_panel_settings_outlined),
            label: const Text(AppStrings.makeCoOwner),
          );
  }
}

class MemberRoleBadge extends StatelessWidget {
  const MemberRoleBadge({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCoOwner = role == 'co_owner';
    final isOwner = role == 'owner';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isOwner
            ? theme.colorScheme.primaryContainer
            : isCoOwner
                ? theme.colorScheme.secondaryContainer
                : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        roleLabel(role),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: isOwner
              ? theme.colorScheme.onPrimaryContainer
              : isCoOwner
                  ? theme.colorScheme.onSecondaryContainer
                  : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
