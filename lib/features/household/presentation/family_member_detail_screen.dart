import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../core/strings/app_strings.dart';
import '../../../shared/models/family_member.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../../../shared/widgets/loading_button.dart';
import '../data/family_repository.dart';
import '../data/household_repository.dart';

class FamilyMemberDetailScreen extends ConsumerStatefulWidget {
  const FamilyMemberDetailScreen({super.key, required this.memberId});

  final String memberId;

  @override
  ConsumerState<FamilyMemberDetailScreen> createState() =>
      _FamilyMemberDetailScreenState();
}

class _FamilyMemberDetailScreenState extends ConsumerState<FamilyMemberDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  bool _saving = false;
  String? _error;

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
  String? _dietaryPreference;
  bool _loaded = false;

  @override
  void dispose() {
    _tabs.dispose();
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
    super.dispose();
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
    _dietaryPreference = details.dietaryPreference;
    _loaded = true;
  }

  FamilyMemberDetails _buildDetails(FamilyMember member, FamilyMemberDetails? existing) {
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
    );
  }

  String? _emptyToNull(String value) =>
      value.trim().isEmpty ? null : value.trim();

  Future<void> _save(FamilyMember member, FamilyMemberDetails? existing) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(familyRepositoryProvider).upsertDetails(
            member.id,
            _buildDetails(member, existing),
          );
      ref.invalidate(familyMemberDetailsProvider(member.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.saved)),
        );
      }
    } catch (e) {
      setState(() => _error = ApiErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove(FamilyMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.removeMember),
        content: Text('Remove ${member.displayName} from the family?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
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
      await ref.read(familyRepositoryProvider).removeRosterMember(member.id);
      ref.invalidate(familyRosterProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorFormatter.format(e))),
        );
      }
    }
  }

  Future<void> _leave(String householdId) async {
    try {
      await ref.read(householdRepositoryProvider).leaveHousehold(householdId);
      ref.invalidate(familyRosterProvider);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
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
    final memberAsync = ref.watch(familyMemberProvider(widget.memberId));
    final detailsAsync = ref.watch(familyMemberDetailsProvider(widget.memberId));
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: memberAsync.when(
          data: (m) => Text(m?.displayName ?? AppStrings.members),
          loading: () => const Text(AppStrings.members),
          error: (_, __) => const Text(AppStrings.members),
        ),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: AppStrings.tabOverview),
            Tab(text: AppStrings.tabHealth),
            Tab(text: AppStrings.tabEmergency),
          ],
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
          final isSelf = member.userId == currentUserId;
          final isOwner = ref.watch(householdMembersProvider).valueOrNull?.any(
                (m) => m.userId == currentUserId && m.role == 'owner',
              ) ??
              false;
          final managedByYou =
              member.isRosterOnly && member.createdBy == currentUserId;

          return Column(
            children: [
              if (managedByYou)
                MaterialBanner(
                  content: const Text(AppStrings.managedByYou),
                  leading: const Icon(Icons.supervisor_account_outlined),
                  actions: const [SizedBox.shrink()],
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _overviewTab(member, details, isSelf, isOwner),
                    _formTab(member, details, [
                      AppTextField(controller: _bloodGroup, label: AppStrings.bloodGroup),
                      const SizedBox(height: 12),
                      AppTextField(controller: _allergies, label: AppStrings.allergies, maxLines: 2),
                      const SizedBox(height: 12),
                      AppTextField(controller: _medicines, label: AppStrings.medicines, maxLines: 2),
                      const SizedBox(height: 12),
                      AppTextField(controller: _doctorName, label: AppStrings.doctorName),
                      const SizedBox(height: 12),
                      AppTextField(controller: _doctorPhone, label: AppStrings.doctorPhone, keyboardType: TextInputType.phone),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _dietaryPreference,
                        decoration: const InputDecoration(labelText: AppStrings.diet),
                        items: const [
                          DropdownMenuItem(value: 'veg', child: Text('Vegetarian')),
                          DropdownMenuItem(value: 'non_veg', child: Text('Non-vegetarian')),
                          DropdownMenuItem(value: 'vegan', child: Text('Vegan')),
                          DropdownMenuItem(value: 'other', child: Text('Other')),
                        ],
                        onChanged: (v) => setState(() => _dietaryPreference = v),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(controller: _foodAllergies, label: AppStrings.foodAllergies, maxLines: 2),
                    ]),
                    _formTab(member, details, [
                      AppTextField(controller: _emergencyName, label: AppStrings.emergencyContactName),
                      const SizedBox(height: 12),
                      AppTextField(controller: _emergencyPhone, label: AppStrings.emergencyContactPhone, keyboardType: TextInputType.phone),
                      const SizedBox(height: 12),
                      AppTextField(controller: _emergencyRelation, label: AppStrings.emergencyContactRelation),
                      const SizedBox(height: 12),
                      AppTextField(controller: _notes, label: AppStrings.notes, maxLines: 4),
                    ]),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _overviewTab(
    FamilyMember member,
    FamilyMemberDetails? details,
    bool isSelf,
    bool isOwner,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoRow(AppStrings.relationship, member.relationshipLabel),
        _infoRow(AppStrings.memberType, member.isAppMember ? AppStrings.appMember : AppStrings.profileOnly),
        if (member.isPendingInvite)
          _infoRow(AppStrings.status, AppStrings.pendingInvite),
        if (member.invitedEmail != null)
          _infoRow(AppStrings.email, member.invitedEmail!),
        if (details?.phone != null || member.phone != null)
          _infoRow(AppStrings.phone, details?.phone ?? member.phone!),
        if (details?.dateOfBirth != null || member.dateOfBirth != null)
          _infoRow(
            AppStrings.dateOfBirth,
            Formatters.date(details?.dateOfBirth ?? member.dateOfBirth!),
          ),
        if (details?.workPlace != null)
          _infoRow(AppStrings.workPlace, details!.workPlace!),
        if (details?.schoolName != null)
          _infoRow(AppStrings.schoolName, details!.schoolName!),
        const SizedBox(height: 16),
        AppTextField(controller: _phone, label: AppStrings.phone),
        const SizedBox(height: 12),
        AppTextField(controller: _altPhone, label: AppStrings.altPhone),
        const SizedBox(height: 12),
        AppTextField(controller: _workPlace, label: AppStrings.workPlace),
        const SizedBox(height: 12),
        AppTextField(controller: _schoolName, label: AppStrings.schoolName),
        const SizedBox(height: 16),
        if (_error != null)
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        const SizedBox(height: 8),
        LoadingButton(
          label: AppStrings.save,
          isLoading: _saving,
          onPressed: () => _save(member, details),
        ),
        if (isSelf && !isOwner) ...[
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => _leave(member.householdId),
            child: const Text(AppStrings.leaveHousehold),
          ),
        ],
        if (isOwner && member.relationship != 'self') ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _remove(member),
            child: Text(
              AppStrings.removeMember,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ],
    );
  }

  Widget _formTab(
    FamilyMember member,
    FamilyMemberDetails? details,
    List<Widget> fields,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...fields,
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 16),
        LoadingButton(
          label: AppStrings.save,
          isLoading: _saving,
          onPressed: () => _save(member, details),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
