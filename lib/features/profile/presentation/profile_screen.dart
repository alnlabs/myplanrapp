import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../core/strings/app_strings.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../../../shared/widgets/loading_button.dart';
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
  ConsumerState<_BasicProfileScreen> createState() => _BasicProfileScreenState();
}

class _BasicProfileScreenState extends ConsumerState<_BasicProfileScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _loaded = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _loadName(String? name) {
    if (_loaded || name == null) return;
    _nameController.text = name;
    _loaded = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .updateDisplayName(_nameController.text.trim());
      ref.invalidate(userProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.saved)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final email = ref.watch(supabaseClientProvider).auth.currentUser?.email;

    profileAsync.whenData((profile) => _loadName(profile?.displayName));

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profileTitle)),
      body: AsyncScreenBody(
        value: profileAsync,
        onRetry: () => ref.invalidate(userProfileProvider),
        builder: (profile) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                AppStrings.accountInfo,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              if (email != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.email_outlined),
                  title: const Text(AppStrings.email),
                  subtitle: Text(email),
                ),
              const SizedBox(height: 8),
              Form(
                key: _formKey,
                child: AppTextField(
                  controller: _nameController,
                  label: AppStrings.displayName,
                  validator: Validators.required,
                ),
              ),
              const SizedBox(height: 16),
              LoadingButton(
                label: AppStrings.save,
                isLoading: _loading,
                onPressed: _save,
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.profileDetailsHint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.noHousehold,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}
