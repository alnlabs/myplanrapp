import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../auth/data/auth_repository.dart';

class AccountRestoreScreen extends ConsumerStatefulWidget {
  const AccountRestoreScreen({super.key});

  @override
  ConsumerState<AccountRestoreScreen> createState() =>
      _AccountRestoreScreenState();
}

class _AccountRestoreScreenState extends ConsumerState<AccountRestoreScreen> {
  bool _loading = false;

  Future<void> _restore() async {
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).restoreAccount();
      ref.invalidate(userProfileProvider);
      final profile = await ref.read(userProfileProvider.future);
      if (!mounted) return;
      if (profile?.hasHousehold ?? false) {
        context.go('/home');
      } else {
        context.go('/household-setup');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorFormatter.format(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.valueOrNull;
    final purgeAt = profile?.deletionPurgeAt;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.accountRestoreTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.restore_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.accountRestoreTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                purgeAt != null
                    ? AppStrings.accountRestoreBodyWithDate(
                        Formatters.date(purgeAt),
                      )
                    : AppStrings.accountRestoreBody,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
              ),
              const Spacer(),
              LoadingButton(
                label: AppStrings.accountRestoreKeep,
                isLoading: _loading,
                onPressed: _restore,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loading ? null : _signOut,
                child: const Text(AppStrings.signOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
