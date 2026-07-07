import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../shared/constants/asset_constants.dart';
import '../../../shared/models/home_asset.dart';
import '../../auth/data/auth_repository.dart';

class AssetRepository {
  AssetRepository(this._client);

  final SupabaseClient _client;

  Future<List<HomeAsset>> fetchAssets(String householdId) async {
    final data = await _client
        .from('home_assets')
        .select()
        .eq('household_id', householdId)
        .neq('status', 'disposed')
        .order('name');
    return (data as List)
        .map((e) => HomeAsset.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<HomeAsset>> fetchWarrantyExpiring(String householdId) async {
    final assets = await fetchAssets(householdId);
    return assets
        .where((a) => a.warrantyStatus == WarrantyStatus.expiring)
        .toList();
  }

  Future<HomeAsset?> fetchAsset(String id) async {
    final data =
        await _client.from('home_assets').select().eq('id', id).maybeSingle();
    if (data == null) return null;
    return HomeAsset.fromJson(data);
  }

  Future<HomeAsset> createAsset(HomeAsset asset, String householdId) async {
    final userId = _client.auth.currentUser?.id;
    final data = await _client
        .from('home_assets')
        .insert(asset.toJson(householdId, userId))
        .select()
        .single();
    return HomeAsset.fromJson(data);
  }

  Future<HomeAsset> updateAsset(HomeAsset asset) async {
    final userId = _client.auth.currentUser?.id;
    final payload = asset.toJson(asset.householdId, userId);
    payload.remove('household_id');
    payload.remove('created_by');

    final data = await _client
        .from('home_assets')
        .update(payload)
        .eq('id', asset.id)
        .select()
        .single();
    return HomeAsset.fromJson(data);
  }

  Future<void> deleteAsset(String id) async {
    await _client.from('home_assets').delete().eq('id', id);
  }

  Future<List<AssetServiceRecord>> fetchServiceRecords(String assetId) async {
    final data = await _client
        .from('asset_service_records')
        .select()
        .eq('asset_id', assetId)
        .order('service_date', ascending: false);
    return (data as List)
        .map((e) => AssetServiceRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addServiceRecord(AssetServiceRecord record) async {
    final userId = _client.auth.currentUser?.id;
    await _client.from('asset_service_records').insert(
          record.toInsertJson(record.assetId, record.householdId, userId),
        );
  }
}

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepository(ref.watch(supabaseClientProvider));
});

final homeAssetsProvider = FutureProvider<List<HomeAsset>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return [];
  return ref.watch(assetRepositoryProvider).fetchAssets(householdId);
});

final warrantyExpiringAssetsProvider = FutureProvider<List<HomeAsset>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return [];
  return ref.watch(assetRepositoryProvider).fetchWarrantyExpiring(householdId);
});

final homeAssetProvider = FutureProvider.family<HomeAsset?, String>((ref, id) async {
  return ref.watch(assetRepositoryProvider).fetchAsset(id);
});

final assetServiceRecordsProvider =
    FutureProvider.family<List<AssetServiceRecord>, String>((ref, assetId) async {
  return ref.watch(assetRepositoryProvider).fetchServiceRecords(assetId);
});
