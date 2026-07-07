import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../auth/data/auth_repository.dart';
import '../data/family_repository.dart';
import '../data/household_repository.dart';

class HouseholdSetupScreen extends ConsumerStatefulWidget {
  const HouseholdSetupScreen({super.key});

  @override
  ConsumerState<HouseholdSetupScreen> createState() =>
      _HouseholdSetupScreenState();
}

class _HouseholdSetupScreenState extends ConsumerState<HouseholdSetupScreen> {
  final _createFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createHousehold() async {
    if (!_createFormKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final householdId = await ref
          .read(householdRepositoryProvider)
          .createHousehold(_nameController.text.trim());
      ref.invalidate(userProfileProvider);
      ref.invalidate(activeHouseholdProvider);
      ref.invalidate(familyRosterProvider);
      if (mounted) context.go('/setup-wizard?householdId=$householdId');
    } catch (e) {
      setState(() => _error = ApiErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _acceptInvite(String householdId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(householdRepositoryProvider).acceptInvite(householdId);
      ref.invalidate(userProfileProvider);
      ref.invalidate(activeHouseholdProvider);
      ref.invalidate(familyRosterProvider);
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = ApiErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invitesAsync = ref.watch(_pendingInvitesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.householdTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.noHousehold,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Form(
                key: _createFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _nameController,
                      label: AppStrings.householdName,
                      validator: Validators.required,
                    ),
                    const SizedBox(height: 16),
                    LoadingButton(
                      label: AppStrings.createHousehold,
                      isLoading: _loading,
                      onPressed: _createHousehold,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              invitesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
                data: (invites) {
                  if (invites.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.joinHousehold,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ...invites.map((invite) {
                        final household =
                            invite['households'] as Map<String, dynamic>?;
                        final name = household?['name'] as String? ?? 'Family';
                        return Card(
                          child: ListTile(
                            title: Text(name),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _loading
                                ? null
                                : () => _acceptInvite(
                                      invite['household_id'] as String,
                                    ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

final _pendingInvitesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(householdRepositoryProvider).fetchPendingInvitesForUser();
});
