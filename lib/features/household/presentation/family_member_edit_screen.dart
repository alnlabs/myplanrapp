import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../core/strings/app_strings.dart';
import '../../../shared/models/family_member.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../auth/data/auth_repository.dart';
import '../data/family_repository.dart';
import 'member_avatar_picker.dart';

class FamilyMemberEditScreen extends ConsumerStatefulWidget {
  const FamilyMemberEditScreen({
    super.key,
    required this.memberId,
    this.profileMode = false,
  });

  final String memberId;
  final bool profileMode;

  @override
  ConsumerState<FamilyMemberEditScreen> createState() =>
      _FamilyMemberEditScreenState();
}

class _FamilyMemberEditScreenState
    extends ConsumerState<FamilyMemberEditScreen> {
  bool _saving = false;
  String? _error;
  bool _loaded = false;

  final _displayName = TextEditingController();
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
  String? _dietaryPreference;
  Map<String, bool> _visibility = {
    MemberVisibilityKeys.phone: true,
    MemberVisibilityKeys.health: true,
    MemberVisibilityKeys.emergency: true,
  };

  @override
  void dispose() {
    _displayName.dispose();
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
    super.dispose();
  }

  void _loadProfileName(String? name) {
    if (!widget.profileMode || name == null) return;
    if (_displayName.text.isEmpty) _displayName.text = name;
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
        for (final key in MemberVisibilityKeys.all) key: details.isVisible(key),
      };
    }
    _loaded = true;
  }

  String? _emptyToNull(String value) =>
      value.trim().isEmpty ? null : value.trim();

  FamilyMemberDetails _buildDetails(
    FamilyMember member,
    FamilyMemberDetails? existing,
  ) {
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
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      setState(() => _error = ApiErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberAsync = ref.watch(familyMemberProvider(widget.memberId));
    final detailsAsync = ref.watch(familyMemberDetailsProvider(widget.memberId));
    final profileAsync = ref.watch(userProfileProvider);
    final email = ref.watch(supabaseClientProvider).auth.currentUser?.email;

    profileAsync.whenData((profile) => _loadProfileName(profile?.displayName));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.profileMode
              ? AppStrings.editProfile
              : AppStrings.editDetails,
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              MemberAvatarPicker(
                familyMemberId: member.id,
                householdId: member.householdId,
                displayName: member.listLabel,
                avatarPath: details?.avatarUrl,
                canEdit: true,
                existingDetails: details ??
                    FamilyMemberDetails(
                      familyMemberId: member.id,
                      householdId: member.householdId,
                      userId: member.userId,
                    ),
              ),
              const SizedBox(height: 20),
              if (widget.profileMode) ...[
                _sectionTitle(AppStrings.accountInfo),
                if (email != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.email_outlined),
                      title: const Text(AppStrings.email),
                      subtitle: Text(email),
                    ),
                  ),
                AppTextField(
                  controller: _displayName,
                  label: AppStrings.displayName,
                ),
                const SizedBox(height: 24),
              ],
              _sectionTitle(AppStrings.sectionContact),
              _field(_phone, AppStrings.phone,
                  keyboardType: TextInputType.phone),
              _field(_altPhone, AppStrings.altPhone,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 24),
              _sectionTitle(AppStrings.sectionWorkSchool),
              _field(_workPlace, AppStrings.workPlace),
              _field(_schoolName, AppStrings.schoolName),
              const SizedBox(height: 24),
              _sectionTitle(AppStrings.tabHealth),
              _field(_bloodGroup, AppStrings.bloodGroup),
              _field(_allergies, AppStrings.allergies, maxLines: 2),
              _field(_medicines, AppStrings.medicines, maxLines: 2),
              _field(_doctorName, AppStrings.doctorName),
              _field(_doctorPhone, AppStrings.doctorPhone,
                  keyboardType: TextInputType.phone),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: _dietaryPreference,
                  decoration: const InputDecoration(
                    labelText: AppStrings.diet,
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'veg', child: Text('Vegetarian')),
                    DropdownMenuItem(
                        value: 'non_veg', child: Text('Non-vegetarian')),
                    DropdownMenuItem(value: 'vegan', child: Text('Vegan')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => _dietaryPreference = v),
                ),
              ),
              _field(_foodAllergies, AppStrings.foodAllergies, maxLines: 2),
              const SizedBox(height: 24),
              _sectionTitle(AppStrings.tabEmergency),
              _field(_emergencyName, AppStrings.emergencyContactName),
              _field(_emergencyPhone, AppStrings.emergencyContactPhone,
                  keyboardType: TextInputType.phone),
              _field(_emergencyRelation, AppStrings.emergencyContactRelation),
              _field(_notes, AppStrings.notes, maxLines: 4),
              const SizedBox(height: 24),
              _sectionTitle(AppStrings.clothingSizes),
              _field(_shirtSize, AppStrings.shirtSize),
              _field(_pantsSize, AppStrings.pantsSize),
              _field(_shoeSize, AppStrings.shoeSize),
              const SizedBox(height: 24),
              _sectionTitle(AppStrings.fieldVisibility),
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
              const SizedBox(height: 20),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 8),
              ],
              LoadingButton(
                label: AppStrings.save,
                isLoading: _saving,
                onPressed: () => _save(member, details),
              ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppTextField(
        controller: controller,
        label: label,
        keyboardType: keyboardType,
        maxLines: maxLines,
      ),
    );
  }
}
