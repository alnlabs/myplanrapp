import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../core/strings/app_strings.dart';
import '../../../shared/models/family_member.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../data/family_repository.dart';
import '../data/household_repository.dart';
import 'add_family_member_screen.dart';
import 'family_member_detail_screen.dart';
import 'household_features_screen.dart';

class HouseholdScreen extends ConsumerWidget {
  const HouseholdScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdAsync = ref.watch(activeHouseholdProvider);
    final rosterAsync = ref.watch(familyRosterProvider);
    final membersAsync = ref.watch(householdMembersProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    final isOwner = membersAsync.valueOrNull?.any(
          (m) => m.userId == currentUserId && m.role == 'owner',
        ) ??
        false;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.householdTitle)),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AddFamilyMemberScreen(),
                ),
              ),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text(AppStrings.addFamilyMember),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
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
          if (isOwner) ...[
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.tune_outlined),
                title: const Text(AppStrings.featureSettings),
                subtitle: const Text(AppStrings.featureSettingsHint),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const HouseholdFeaturesScreen(),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          AsyncScreenBody(
            value: rosterAsync,
            onRetry: () => ref.invalidate(familyRosterProvider),
            builder: (roster) {
              if (roster.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(AppStrings.emptyFamilyRoster),
                );
              }
              return Column(
                children: roster.map((m) => _MemberTile(member: m)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final FamilyMember member;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            member.displayName.isNotEmpty
                ? member.displayName[0].toUpperCase()
                : '?',
          ),
        ),
        title: Text(member.displayName),
        subtitle: Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _Badge(label: member.relationshipLabel),
            _Badge(
              label: member.isAppMember ? AppStrings.appMember : AppStrings.profileOnly,
              muted: true,
            ),
            if (member.isPendingInvite)
              _Badge(label: AppStrings.pendingInvite, highlight: true),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => FamilyMemberDetailScreen(memberId: member.id),
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
