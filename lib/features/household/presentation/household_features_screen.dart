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

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.featureSettings)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(AppStrings.interestsQuestion),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: HouseholdInterests.all.map((interest) {
              final selected = _selectedInterests.contains(interest.id);
              return FilterChip(
                label: Text('${interest.icon} ${interest.label}'),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _selectedInterests.add(interest.id);
                    } else if (_selectedInterests.length > 1) {
                      _selectedInterests.remove(interest.id);
                    }
                  });
                },
              );
            }).toList(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
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
