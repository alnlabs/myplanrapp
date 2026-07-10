import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/family_relationships.dart';
import '../../../shared/constants/household_modules.dart';
import '../../../shared/models/family_member.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../auth/data/auth_repository.dart';
import '../data/family_repository.dart';
import '../data/household_settings_repository.dart';

class SetupWizardScreen extends ConsumerStatefulWidget {
  const SetupWizardScreen({super.key, required this.householdId});

  final String householdId;

  @override
  ConsumerState<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends ConsumerState<SetupWizardScreen> {
  final _pageController = PageController();
  final _displayName = TextEditingController();
  final _phone = TextEditingController();
  final _memberName = TextEditingController();

  final Set<String> _selected = {HouseholdInterests.groceries};
  String _memberRelationship = FamilyRelationships.spouse.value;
  int _step = 0;
  bool _loading = false;
  bool _profileLoaded = false;
  String? _error;

  bool get _showQuickStart => _selected.contains(HouseholdInterests.groceries);

  int get _totalSteps => 2 + (_showQuickStart ? 1 : 0) + 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _displayName.dispose();
    _phone.dispose();
    _memberName.dispose();
    super.dispose();
  }

  void _loadProfile() {
    if (_profileLoaded) return;
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile?.displayName != null) {
      _displayName.text = profile!.displayName!;
    }
    _profileLoaded = true;
  }

  void _next() async {
    final kind = _stepKindForIndex(_step);
    if (kind == 1) {
      if (!_formKey.currentState!.validate()) return;
      setState(() {
        _loading = true;
        _error = null;
      });
      try {
        await _saveProfile();
      } catch (e) {
        setState(() => _error = ApiErrorFormatter.format(e));
        return;
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }

    if (_step < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      setState(() => _step++);
      return;
    }
    await _finish();
  }

  void _skipStep() {
    if (_step < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      setState(() => _step++);
      return;
    }
    _finish();
  }

  void _back() {
    if (_step == 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
    setState(() => _step--);
  }

  final _formKey = GlobalKey<FormState>();

  Future<void> _saveProfile() async {
    final name = _displayName.text.trim();
    if (name.isNotEmpty) {
      await ref.read(authRepositoryProvider).updateDisplayName(name);
      ref.invalidate(userProfileProvider);
    }

    final phone = _phone.text.trim();
    if (phone.isEmpty) return;

    final roster = await ref.read(familyRosterProvider.future);
    final userId = ref.read(currentUserIdProvider);
    FamilyMember? self;
    for (final m in roster) {
      if (m.userId == userId || m.relationship == 'self') {
        self = m;
        break;
      }
    }
    if (self == null) return;

    await ref.read(familyRepositoryProvider).upsertDetails(
          self.id,
          FamilyMemberDetails(
            familyMemberId: self.id,
            householdId: widget.householdId,
            userId: userId,
            phone: phone,
          ),
        );
    ref.invalidate(familyRosterProvider);
  }

  Future<void> _maybeAddFamilyMember() async {
    final name = _memberName.text.trim();
    if (name.isEmpty) return;
    await ref.read(familyRepositoryProvider).addRosterMember(
          householdId: widget.householdId,
          displayName: name,
          relationship: _memberRelationship,
        );
    ref.invalidate(familyRosterProvider);
  }

  Future<void> _finish() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _maybeAddFamilyMember();

      final modules =
          HouseholdInterests.modulesFromInterests(_selected).toList();
      await ref.read(householdSettingsRepositoryProvider).updateEnabledModules(
            widget.householdId,
            modules,
          );
      ref.invalidate(householdSettingsProvider);
      ref.invalidate(enabledModulesProvider);
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = ApiErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _stepKindForIndex(int index) {
    var i = 0;
    if (index == i++) return 0; // interests
    if (index == i++) return 1; // profile
    if (_showQuickStart) {
      if (index == i++) return 2; // quick start
    }
    return 3; // family
  }

  bool get _canSkipCurrentStep {
    final kind = _stepKindForIndex(_step);
    return kind == 2 || kind == 3;
  }

  String _primaryButtonLabel() {
    if (_step < _totalSteps - 1) return AppStrings.next;
    return AppStrings.wizardFinish;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(userProfileProvider).whenData((profile) {
      if (!_profileLoaded && profile?.displayName != null) {
        _displayName.text = profile!.displayName!;
        _profileLoaded = true;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.setupWizardTitle),
        leading: _step > 0
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back)
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Row(
              children: [
                Text(
                  '${AppStrings.wizardStepOf} ${_step + 1} / $_totalSteps',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_step + 1) / _totalSteps,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _interestsStep(),
                _profileStep(),
                if (_showQuickStart) _quickStartStep(),
                _familyStep(),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LoadingButton(
                  label: _primaryButtonLabel(),
                  isLoading: _loading,
                  onPressed: _next,
                ),
                if (_canSkipCurrentStep) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loading ? null : _skipStep,
                    child: const Text(AppStrings.skipForNow),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _interestsStep() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          AppStrings.interestsQuestion,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.interestsHint,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: HouseholdInterests.all.map((interest) {
            final selected = _selected.contains(interest.id);
            return FilterChip(
              label: Text('${interest.icon} ${interest.label}'),
              selected: selected,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    _selected.add(interest.id);
                  } else if (_selected.length > 1) {
                    _selected.remove(interest.id);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _profileStep() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          AppStrings.wizardProfileTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.wizardProfileHint,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: _displayName,
                label: AppStrings.displayName,
                validator: Validators.required,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _phone,
                label: AppStrings.phoneOptional,
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quickStartStep() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          AppStrings.wizardQuickStartTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.wizardQuickStartHint,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () async {
            await context.push('/pantry/add');
            ref.invalidate(familyRosterProvider);
          },
          icon: const Icon(Icons.add),
          label: const Text(AppStrings.wizardAddPantryItem),
        ),
      ],
    );
  }

  Widget _familyStep() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          AppStrings.wizardFamilyTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.wizardFamilyHint,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 20),
        AppTextField(
          controller: _memberName,
          label: AppStrings.displayName,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _memberRelationship,
          decoration: const InputDecoration(labelText: AppStrings.relationship),
          items: FamilyRelationships.inviteOptions
              .map((r) => DropdownMenuItem(value: r.value, child: Text(r.label)))
              .toList(),
          onChanged: (v) => setState(() => _memberRelationship = v!),
        ),
      ],
    );
  }
}
