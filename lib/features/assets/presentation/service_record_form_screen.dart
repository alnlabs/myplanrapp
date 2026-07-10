import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/asset_constants.dart';
import '../../../shared/models/home_asset.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/form_screen_body.dart';
import '../data/asset_repository.dart';
import '../utils/service_record_form_validators.dart';

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
  final _formKey = GlobalKey<FormState>();
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

  String? _validateShopName(String? value) {
    return validateServiceRecordShopName(value, serviceType: _serviceType);
  }

  String? _validateCost(String? value) {
    return validateServiceRecordCost(value);
  }

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
    if (!_formKey.currentState!.validate()) return;
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
      body: FormScreenBody(
        formKey: _formKey,
        children: [
          DropdownButtonFormField<String>(
            value: _serviceType,
            decoration: const InputDecoration(labelText: AppStrings.serviceType),
            items: ServiceTypes.all
                .map((t) =>
                    DropdownMenuItem(value: t.value, child: Text(t.label)))
                .toList(),
            onChanged: (v) => setState(() => _serviceType = v!),
          ),
          const SizedBox(height: kFormFieldSpacing),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.serviceDate),
            subtitle: Text(Formatters.date(_serviceDate)),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _serviceDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _serviceDate = picked);
            },
          ),
          const SizedBox(height: kFormFieldSpacing),
          if (_serviceType == ServiceTypes.shopRepair) ...[
            AppTextField(
              controller: _shopName,
              label: AppStrings.shopName,
              validator: _validateShopName,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: kFormFieldSpacing),
            AppTextField(
              controller: _shopPhone,
              label: AppStrings.shopPhone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
          ],
          if (_serviceType == ServiceTypes.thirdParty) ...[
            AppTextField(
              controller: _platformName,
              label: AppStrings.platformName,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: kFormFieldSpacing),
            AppTextField(
              controller: _agentName,
              label: AppStrings.agentName,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: kFormFieldSpacing),
            AppTextField(
              controller: _bookingRef,
              label: AppStrings.bookingRef,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: kFormFieldSpacing),
          ],
          AppTextField(
            controller: _cost,
            label: AppStrings.serviceCost,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _validateCost,
          ),
          const SizedBox(height: kFormFieldSpacing),
          AppTextField(
            controller: _notes,
            label: AppStrings.notes,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          FormSaveSection(
            error: _error,
            saveLabel: AppStrings.save,
            isLoading: _loading,
            onSave: _submit,
          ),
        ],
      ),
    );
  }
}
