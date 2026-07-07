import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/asset_constants.dart';
import '../../../shared/models/home_asset.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/offline_guard.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../auth/data/auth_repository.dart';
import '../data/asset_repository.dart';

class AssetFormScreen extends ConsumerStatefulWidget {
  const AssetFormScreen({super.key, this.assetId, this.initialName});

  final String? assetId;
  final String? initialName;

  @override
  ConsumerState<AssetFormScreen> createState() => _AssetFormScreenState();
}

class _AssetFormScreenState extends ConsumerState<AssetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _vendorName = TextEditingController();
  final _purchaseAmount = TextEditingController();
  final _warrantyProvider = TextEditingController();
  final _warrantyNotes = TextEditingController();

  String _category = AssetCategories.other;
  String _itemKind = AssetKinds.permanent;
  String _status = AssetStatuses.active;
  DateTime? _purchaseDate;
  DateTime? _warrantyStart;
  DateTime? _warrantyEnd;
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  bool get _isEdit => widget.assetId != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialName != null) {
      _name.text = widget.initialName!;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _location.dispose();
    _vendorName.dispose();
    _purchaseAmount.dispose();
    _warrantyProvider.dispose();
    _warrantyNotes.dispose();
    super.dispose();
  }

  void _load(HomeAsset asset) {
    if (_loaded) return;
    _name.text = asset.name;
    _description.text = asset.description ?? '';
    _location.text = asset.location ?? '';
    _vendorName.text = asset.vendorName ?? '';
    _purchaseAmount.text = asset.purchaseAmount?.toString() ?? '';
    _warrantyProvider.text = asset.warrantyProvider ?? '';
    _warrantyNotes.text = asset.warrantyNotes ?? '';
    _category = asset.category;
    _itemKind = asset.itemKind;
    _status = asset.status;
    _purchaseDate = asset.purchaseDate;
    _warrantyStart = asset.warrantyStart;
    _warrantyEnd = asset.warrantyEnd;
    _loaded = true;
  }

  Future<void> _pickDate(void Function(DateTime?) setter, DateTime? initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
    );
    if (date != null) setState(() => setter(date));
  }

  HomeAsset _build({HomeAsset? existing}) {
    return HomeAsset(
      id: existing?.id ?? '',
      householdId: existing?.householdId ?? '',
      createdBy: existing?.createdBy,
      name: _name.text.trim(),
      description: _emptyToNull(_description.text),
      category: _category,
      itemKind: _itemKind,
      status: _status,
      location: _emptyToNull(_location.text),
      vendorName: _emptyToNull(_vendorName.text),
      purchaseDate: _purchaseDate,
      purchaseAmount: double.tryParse(_purchaseAmount.text.trim()),
      warrantyStart: _warrantyStart,
      warrantyEnd: _warrantyEnd,
      warrantyProvider: _emptyToNull(_warrantyProvider.text),
      warrantyNotes: _emptyToNull(_warrantyNotes.text),
    );
  }

  String? _emptyToNull(String v) => v.trim().isEmpty ? null : v.trim();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      ref.ensureOnline();
      final profile = await ref.read(userProfileProvider.future);
      final householdId = profile?.activeHouseholdId;
      if (householdId == null) throw Exception(AppStrings.noHousehold);

      final repo = ref.read(assetRepositoryProvider);
      if (_isEdit) {
        final existing = await repo.fetchAsset(widget.assetId!);
        if (existing == null) throw Exception(AppStrings.errorGeneric);
        await repo.updateAsset(_build(existing: existing));
      } else {
        await repo.createAsset(_build(), householdId);
      }

      ref.invalidate(homeAssetsProvider);
      ref.invalidate(warrantyExpiringAssetsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = ApiErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEdit) {
      ref.watch(homeAssetProvider(widget.assetId!)).whenData((a) {
        if (a != null) _load(a);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? AppStrings.editAsset : AppStrings.addAsset),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              AppTextField(
                controller: _name,
                label: AppStrings.assetName,
                validator: Validators.required,
              ),
              const SizedBox(height: 16),
              AppTextField(controller: _description, label: AppStrings.planDescription, maxLines: 2),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: AppStrings.assetCategory),
                items: AssetCategories.all
                    .map((c) => DropdownMenuItem(value: c.value, child: Text(c.label)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _itemKind,
                decoration: const InputDecoration(labelText: AppStrings.assetKind),
                items: AssetKinds.all
                    .map((k) => DropdownMenuItem(value: k.value, child: Text(k.label)))
                    .toList(),
                onChanged: (v) => setState(() => _itemKind = v!),
              ),
              const SizedBox(height: 16),
              AppTextField(controller: _location, label: AppStrings.assetLocation),
              const SizedBox(height: 24),
              Text(AppStrings.purchaseInfo, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              AppTextField(controller: _vendorName, label: AppStrings.whereBought),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(AppStrings.purchaseDate),
                subtitle: Text(_purchaseDate?.toString().split(' ').first ?? AppStrings.none),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today_outlined),
                  onPressed: () => _pickDate((d) => _purchaseDate = d, _purchaseDate),
                ),
              ),
              AppTextField(
                controller: _purchaseAmount,
                label: AppStrings.purchaseAmount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 24),
              Text(AppStrings.warranty, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              AppTextField(controller: _warrantyProvider, label: AppStrings.warrantyProvider),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(AppStrings.warrantyStart),
                subtitle: Text(_warrantyStart?.toString().split(' ').first ?? AppStrings.none),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today_outlined),
                  onPressed: () => _pickDate((d) => _warrantyStart = d, _warrantyStart),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(AppStrings.warrantyEnd),
                subtitle: Text(_warrantyEnd?.toString().split(' ').first ?? AppStrings.none),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today_outlined),
                  onPressed: () => _pickDate((d) => _warrantyEnd = d, _warrantyEnd),
                ),
              ),
              AppTextField(controller: _warrantyNotes, label: AppStrings.warrantyNotes, maxLines: 2),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              LoadingButton(label: AppStrings.save, isLoading: _loading, onPressed: _submit),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
