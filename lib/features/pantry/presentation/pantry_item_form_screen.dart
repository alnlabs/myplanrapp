import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/pantry_constants.dart';
import '../../../shared/models/pantry_item.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/offline_guard.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/form_screen_body.dart';
import '../../../shared/widgets/pantry_availability_chips.dart';
import '../../../shared/widgets/quantity_with_unit_field.dart';
import '../../auth/data/auth_repository.dart';
import '../data/pantry_repository.dart';
import '../data/pantry_items_list_provider.dart';
import '../data/pantry_shop_refresh.dart';
import '../utils/pantry_form_validators.dart';

class PantryItemFormScreen extends ConsumerStatefulWidget {
  const PantryItemFormScreen({super.key, this.item});

  final PantryItem? item;

  @override
  ConsumerState<PantryItemFormScreen> createState() =>
      _PantryItemFormScreenState();
}

class _PantryItemFormScreenState extends ConsumerState<PantryItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _brand;
  late final TextEditingController _quantity;
  late final TextEditingController _threshold;
  late String _unit;
  late String _lowStockUnit;
  String? _category;
  String? _availabilityStatus;
  DateTime? _expiryDate;
  bool _loading = false;
  String? _error;

  bool get isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item?.name ?? '');
    _brand = TextEditingController(text: widget.item?.brand ?? '');
    _quantity = TextEditingController(
      text: widget.item != null && widget.item!.quantity > 0
          ? widget.item!.quantity.toString()
          : '',
    );
    _threshold = TextEditingController(
      text: widget.item?.lowStockThreshold?.toString() ?? '',
    );
    _unit = widget.item?.unit ?? 'kg';
    _lowStockUnit = widget.item?.lowStockUnit ?? _unit;
    _category = widget.item?.category;
    _availabilityStatus = widget.item?.availabilityStatus;
    _expiryDate = widget.item?.expiryDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _quantity.dispose();
    _threshold.dispose();
    super.dispose();
  }

  String? _validateQuantity(String? value) {
    return validatePantryQuantity(
      value,
      hasAvailabilityStatus: _availabilityStatus != null,
    );
  }

  bool _affectsShop() {
    final existing = widget.item;
    if (existing == null) return true;
    final quantityText = _quantity.text.trim();
    final newQty = quantityText.isEmpty ? 0.0 : double.parse(quantityText);
    final thresholdText = _threshold.text.trim();
    final newThreshold =
        thresholdText.isEmpty ? null : double.parse(thresholdText);
    return _availabilityStatus != existing.availabilityStatus ||
        newQty != existing.quantity ||
        newThreshold != existing.lowStockThreshold ||
        _lowStockUnit != existing.lowStockUnit;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final quantityText = _quantity.text.trim();
    final hasQuantity = quantityText.isNotEmpty;
    final hasStatus = _availabilityStatus != null;
    if (!hasQuantity && !hasStatus) {
      setState(() => _error = AppStrings.pantryTrackingRequired);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      ref.ensureOnline();
      final profile = await ref.read(userProfileProvider.future);
      final householdId = profile?.activeHouseholdId;
      if (householdId == null) throw Exception(AppStrings.noHousehold);

      final item = PantryItem(
        id: widget.item?.id ?? '',
        householdId: householdId,
        name: _name.text.trim(),
        brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
        quantity: hasQuantity ? double.parse(quantityText) : 0,
        unit: _unit,
        lowStockThreshold: _threshold.text.trim().isEmpty
            ? null
            : double.parse(_threshold.text.trim()),
        lowStockUnit: _lowStockUnit,
        availabilityStatus: _availabilityStatus,
        category: _category,
        expiryDate: _expiryDate,
      );

      if (isEditing) {
        await ref.read(pantryRepositoryProvider).updateItem(item);
      } else {
        await ref.read(pantryRepositoryProvider).createItem(item, householdId);
      }

      if (_affectsShop()) {
        await refreshPantryAndShop(ref);
      } else {
        await refreshPantryList(ref);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = ApiErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? AppStrings.editItem : AppStrings.addItem),
      ),
      body: FormScreenBody(
        formKey: _formKey,
        children: [
          AppTextField(
            controller: _name,
            label: AppStrings.itemName,
            validator: Validators.required,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: kFormFieldSpacing),
          AppTextField(
            controller: _brand,
            label: AppStrings.brandOptional,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: kFormFieldSpacing),
          PantryAvailabilityChips(
            selected: _availabilityStatus,
            onSelected: (value) => setState(() {
              _availabilityStatus = value;
              _error = null;
            }),
          ),
          const SizedBox(height: kFormFieldSpacing),
          QuantityWithUnitField(
            controller: _quantity,
            label: AppStrings.quantity,
            unit: _unit,
            onUnitChanged: (v) => setState(() {
              _unit = v;
              if (PantryUnits.family(_lowStockUnit) != PantryUnits.family(v)) {
                _lowStockUnit = v;
              }
            }),
            validator: _validateQuantity,
          ),
          const SizedBox(height: kFormFieldSpacing),
          QuantityWithUnitField(
            controller: _threshold,
            label: AppStrings.lowStockAlert,
            unit: _lowStockUnit,
            unitOptions: PantryUnits.compatibleWith(_unit),
            onUnitChanged: (v) => setState(() => _lowStockUnit = v),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              AppStrings.lowStockAlertOptionalHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: kFormFieldSpacing),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(labelText: AppStrings.category),
            items: PantryCategories.values
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: kFormFieldSpacing),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.expiryDate),
            subtitle: Text(
              _expiryDate == null
                  ? AppStrings.notSet
                  : Formatters.date(_expiryDate!),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_expiryDate != null)
                  IconButton(
                    onPressed: () => setState(() => _expiryDate = null),
                    icon: const Icon(Icons.clear),
                  ),
                const Icon(Icons.calendar_today_outlined),
              ],
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _expiryDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
              );
              if (picked != null) setState(() => _expiryDate = picked);
            },
          ),
          const SizedBox(height: 24),
          FormSaveSection(
            error: _error,
            saveLabel: AppStrings.save,
            isLoading: _loading,
            onSave: _save,
          ),
        ],
      ),
    );
  }
}
