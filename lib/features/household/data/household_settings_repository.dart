import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../shared/constants/household_modules.dart';
import '../../auth/data/auth_repository.dart';

class HouseholdSettings {
  const HouseholdSettings({
    required this.householdId,
    required this.enabledModules,
  });

  final String householdId;
  final List<String> enabledModules;

  bool isEnabled(String module) => enabledModules.contains(module);

  factory HouseholdSettings.fromJson(Map<String, dynamic> json) {
    final modules = json['enabled_modules'];
    return HouseholdSettings(
      householdId: json['household_id'] as String,
      enabledModules: modules is List
          ? modules.cast<String>()
          : HouseholdModules.defaultEnabled,
    );
  }
}

class HouseholdSettingsRepository {
  HouseholdSettingsRepository(this._client);

  final SupabaseClient _client;

  Future<HouseholdSettings?> fetchSettings(String householdId) async {
    final data = await _client
        .from('household_settings')
        .select()
        .eq('household_id', householdId)
        .maybeSingle();
    if (data == null) {
      return HouseholdSettings(
        householdId: householdId,
        enabledModules: HouseholdModules.defaultEnabled,
      );
    }
    return HouseholdSettings.fromJson(data);
  }

  Future<void> updateEnabledModules(
    String householdId,
    List<String> modules,
  ) async {
    await _client.rpc('upsert_household_settings', params: {
      'p_household_id': householdId,
      'p_enabled_modules': modules,
    });
  }
}

final householdSettingsRepositoryProvider =
    Provider<HouseholdSettingsRepository>((ref) {
  return HouseholdSettingsRepository(ref.watch(supabaseClientProvider));
});

final householdSettingsProvider = FutureProvider<HouseholdSettings?>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return null;
  return ref.watch(householdSettingsRepositoryProvider).fetchSettings(householdId);
});

final enabledModulesProvider = Provider<Set<String>>((ref) {
  final settings = ref.watch(householdSettingsProvider).valueOrNull;
  if (settings == null) {
    return HouseholdModules.defaultEnabled.toSet();
  }
  return settings.enabledModules.toSet();
});

final isModuleEnabledProvider = Provider.family<bool, String>((ref, module) {
  return ref.watch(enabledModulesProvider).contains(module);
});
