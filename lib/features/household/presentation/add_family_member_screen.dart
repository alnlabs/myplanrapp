import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/family_relationships.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/offline_guard.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../auth/data/auth_repository.dart';
import '../data/family_repository.dart';
import '../data/household_repository.dart';

enum AddMemberKind { inviteApp, profileOnly }

class AddFamilyMemberScreen extends ConsumerStatefulWidget {
  const AddFamilyMemberScreen({super.key});

  @override
  ConsumerState<AddFamilyMemberScreen> createState() =>
      _AddFamilyMemberScreenState();
}

class _AddFamilyMemberScreenState extends ConsumerState<AddFamilyMemberScreen> {
  AddMemberKind _kind = AddMemberKind.inviteApp;
  String _relationship = FamilyRelationships.other.value;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      ref.ensureOnline();
      final profile = await ref.read(userProfileProvider.future);
      final householdId = profile?.activeHouseholdId;
      if (householdId == null) return;

      final repo = ref.read(familyRepositoryProvider);

      if (_kind == AddMemberKind.inviteApp) {
        final emailError = Validators.email(_emailController.text);
        if (emailError != null) {
          setState(() => _error = emailError);
          return;
        }
        await repo.inviteAppMember(
          householdId: householdId,
          email: _emailController.text.trim(),
          relationship: _relationship,
        );
      } else {
        final nameError = Validators.required(_nameController.text);
        if (nameError != null) {
          setState(() => _error = nameError);
          return;
        }
        await repo.addRosterMember(
          householdId: householdId,
          displayName: _nameController.text.trim(),
          relationship: _relationship,
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
        );
      }

      ref.invalidate(familyRosterProvider);
      ref.invalidate(sentPendingInvitesProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _kind == AddMemberKind.inviteApp
                  ? AppStrings.inviteSent
                  : AppStrings.memberAdded,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = ApiErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.addFamilyMember)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SegmentedButton<AddMemberKind>(
            segments: const [
              ButtonSegment(
                value: AddMemberKind.inviteApp,
                label: Text(AppStrings.inviteToApp),
                icon: Icon(Icons.mail_outline),
              ),
              ButtonSegment(
                value: AddMemberKind.profileOnly,
                label: Text(AppStrings.profileOnly),
                icon: Icon(Icons.person_outline),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (value) {
              setState(() => _kind = value.first);
            },
          ),
          const SizedBox(height: 8),
          Text(
            _kind == AddMemberKind.inviteApp
                ? AppStrings.inviteToAppHint
                : AppStrings.profileOnlyHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            value: _relationship,
            decoration: const InputDecoration(labelText: AppStrings.relationship),
            items: FamilyRelationships.inviteOptions
                .map(
                  (r) => DropdownMenuItem(value: r.value, child: Text(r.label)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _relationship = value);
            },
          ),
          const SizedBox(height: 16),
          if (_kind == AddMemberKind.profileOnly) ...[
            AppTextField(
              controller: _nameController,
              label: AppStrings.displayName,
              validator: Validators.required,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _phoneController,
              label: AppStrings.phoneOptional,
              keyboardType: TextInputType.phone,
            ),
          ] else ...[
            AppTextField(
              controller: _emailController,
              label: AppStrings.email,
              validator: Validators.email,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          LoadingButton(
            label: _kind == AddMemberKind.inviteApp
                ? AppStrings.inviteMember
                : AppStrings.addMember,
            isLoading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
