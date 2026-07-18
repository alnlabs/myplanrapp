import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../core/strings/app_strings.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../../auth/data/auth_repository.dart';
import '../../household/data/family_repository.dart';
import '../../household/presentation/family_member_detail_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(currentUserFamilyMemberProvider);

    return memberAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.profileTitle)),
        body: Center(child: Text(error.toString())),
      ),
      data: (member) {
        if (member != null) {
          return FamilyMemberDetailScreen(
            memberId: member.id,
            profileMode: true,
          );
        }
        return const _BasicProfileScreen();
      },
    );
  }
}

class _BasicProfileScreen extends ConsumerStatefulWidget {
  const _BasicProfileScreen();

  @override
  ConsumerState<_BasicProfileScreen> createState() =>
      _BasicProfileScreenState();
}

class _BasicProfileScreenState extends ConsumerState<_BasicProfileScreen> {
  Future<void> _editName(String? current) async {
    final controller = TextEditingController(text: current ?? '');
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.editProfile),
        content: Form(
          key: formKey,
          child: AppTextField(
            controller: controller,
            label: AppStrings.displayName,
            validator: Validators.required,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
    if (saved == null) return;
    try {
      await ref.read(authRepositoryProvider).updateDisplayName(saved);
      ref.invalidate(userProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.saved)),
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

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final email = ref.watch(supabaseClientProvider).auth.currentUser?.email;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profileTitle),
        actions: [
          IconButton(
            onPressed: () =>
                _editName(profileAsync.valueOrNull?.displayName),
            icon: const Icon(Icons.edit_outlined),
            tooltip: AppStrings.editProfile,
          ),
        ],
      ),
      body: AsyncScreenBody(
        value: profileAsync,
        onRetry: () => ref.invalidate(userProfileProvider),
        builder: (UserProfile? profile) {
          final name = profile?.displayName?.trim();
          final initial = (name != null && name.isNotEmpty)
              ? name[0].toUpperCase()
              : '?';
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        initial,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name?.isNotEmpty == true ? name! : AppStrings.notSet,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (email != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () => _editName(name),
                icon: const Icon(Icons.edit_outlined),
                label: const Text(AppStrings.editProfile),
              ),
              const SizedBox(height: 24),
              Card(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.groups_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.profileDetailsHint,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppStrings.noHousehold,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
