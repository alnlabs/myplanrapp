import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/household_modules.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/offline_guard.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../auth/data/auth_repository.dart';
import '../data/household_settings_repository.dart';

class HouseholdFeaturesScreen extends ConsumerStatefulWidget {
  const HouseholdFeaturesScreen({super.key});

  @override
  ConsumerState<HouseholdFeaturesScreen> createState() =>
      _HouseholdFeaturesScreenState();
}

class _HouseholdFeaturesScreenState extends ConsumerState<HouseholdFeaturesScreen> {
  Set<String> _selectedInterests = {};
  bool _loaded = false;
  bool _saving = false;
  String? _error;

  void _loadFromModules(Set<String> modules) {
    if (_loaded) return;
    _selectedInterests = {};
    for (final interest in HouseholdInterests.all) {
      final interestModules =
          HouseholdInterests.modulesFromInterests({interest.id});
      if (interestModules.every(modules.contains)) {
        _selectedInterests.add(interest.id);
      }
    }
    if (_selectedInterests.isEmpty) {
      _selectedInterests = {HouseholdInterests.groceries};
    }
    _loaded = true;
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      ref.ensureOnline();
      final profile = await ref.read(userProfileProvider.future);
      final householdId = profile?.activeHouseholdId;
      if (householdId == null) return;

      final modules =
          HouseholdInterests.modulesFromInterests(_selectedInterests).toList();
      await ref.read(householdSettingsRepositoryProvider).updateEnabledModules(
            householdId,
            modules,
          );
      ref.invalidate(householdSettingsProvider);
      ref.invalidate(enabledModulesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.featuresSaved)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = ApiErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modules = ref.watch(enabledModulesProvider);
    _loadFromModules(modules);

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.featureSettings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            AppStrings.interestsQuestion,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.featureSettingsHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ...HouseholdInterests.all.map((interest) {
            final selected = _selectedInterests.contains(interest.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _InterestCard(
                icon: interest.icon,
                label: interest.label,
                selected: selected,
                onTap: () {
                  setState(() {
                    if (selected) {
                      if (_selectedInterests.length > 1) {
                        _selectedInterests.remove(interest.id);
                      }
                    } else {
                      _selectedInterests.add(interest.id);
                    }
                  });
                },
              ),
            );
          }),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 16),
          LoadingButton(
            label: AppStrings.save,
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _InterestCard extends StatelessWidget {
  const _InterestCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant;

    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer.withOpacity(0.35)
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: selected ? 1.6 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
