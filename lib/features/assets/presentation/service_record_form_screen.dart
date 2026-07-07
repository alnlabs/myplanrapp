import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/asset_constants.dart';
import '../../../shared/models/home_asset.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_button.dart';
import '../data/asset_repository.dart';

class ServiceRecordFormScreen extends ConsumerStatefulWidget {
  const ServiceRecordFormScreen({
    super.key,
    required this.assetId,
    required this.householdId,
  });

  final String assetId;
  final String householdId;

  @override
  ConsumerState<ServiceRecordFormScreen> createState() =>
      _ServiceRecordFormScreenState();
}

class _ServiceRecordFormScreenState extends ConsumerState<ServiceRecordFormScreen> {
  String _serviceType = ServiceTypes.shopRepair;
  final _shopName = TextEditingController();
  final _shopPhone = TextEditingController();
  final _platformName = TextEditingController();
  final _agentName = TextEditingController();
  final _bookingRef = TextEditingController();
  final _cost = TextEditingController();
  final _notes = TextEditingController();
  DateTime _serviceDate = DateTime.now();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _shopName.dispose();
    _shopPhone.dispose();
    _platformName.dispose();
    _agentName.dispose();
    _bookingRef.dispose();
    _cost.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final record = AssetServiceRecord(
        id: '',
        assetId: widget.assetId,
        householdId: widget.householdId,
        serviceType: _serviceType,
        serviceDate: _serviceDate,
        shopName: _shopName.text.trim().isEmpty ? null : _shopName.text.trim(),
        shopPhone: _shopPhone.text.trim().isEmpty ? null : _shopPhone.text.trim(),
        platformName:
            _platformName.text.trim().isEmpty ? null : _platformName.text.trim(),
        agentName: _agentName.text.trim().isEmpty ? null : _agentName.text.trim(),
        bookingRef: _bookingRef.text.trim().isEmpty ? null : _bookingRef.text.trim(),
        cost: double.tryParse(_cost.text.trim()),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );

      await ref.read(assetRepositoryProvider).addServiceRecord(record);
      ref.invalidate(assetServiceRecordsProvider(widget.assetId));

      if (_serviceType == ServiceTypes.shopRepair ||
          _serviceType == ServiceTypes.thirdParty) {
        final asset = await ref.read(assetRepositoryProvider).fetchAsset(widget.assetId);
        if (asset != null && asset.status == AssetStatuses.active) {
          await ref.read(assetRepositoryProvider).updateAsset(
                HomeAsset(
                  id: asset.id,
                  householdId: asset.householdId,
                  name: asset.name,
                  category: asset.category,
                  itemKind: asset.itemKind,
                  status: AssetStatuses.underRepair,
                  createdBy: asset.createdBy,
                  description: asset.description,
                  location: asset.location,
                  warrantyEnd: asset.warrantyEnd,
                ),
              );
          ref.invalidate(homeAssetProvider(widget.assetId));
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = ApiErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.logRepair)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          DropdownButtonFormField<String>(
            value: _serviceType,
            decoration: const InputDecoration(labelText: AppStrings.serviceType),
            items: ServiceTypes.all
                .map((t) => DropdownMenuItem(value: t.value, child: Text(t.label)))
                .toList(),
            onChanged: (v) => setState(() => _serviceType = v!),
          ),
          const SizedBox(height: 16),
          if (_serviceType == ServiceTypes.shopRepair) ...[
            AppTextField(controller: _shopName, label: AppStrings.shopName),
            const SizedBox(height: 12),
            AppTextField(controller: _shopPhone, label: AppStrings.shopPhone, keyboardType: TextInputType.phone),
          ],
          if (_serviceType == ServiceTypes.thirdParty) ...[
            AppTextField(controller: _platformName, label: AppStrings.platformName),
            const SizedBox(height: 12),
            AppTextField(controller: _agentName, label: AppStrings.agentName),
            const SizedBox(height: 12),
            AppTextField(controller: _bookingRef, label: AppStrings.bookingRef),
          ],
          AppTextField(
            controller: _cost,
            label: AppStrings.serviceCost,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          AppTextField(controller: _notes, label: AppStrings.notes, maxLines: 3),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          LoadingButton(label: AppStrings.save, isLoading: _loading, onPressed: _submit),
        ],
      ),
    );
  }
}
