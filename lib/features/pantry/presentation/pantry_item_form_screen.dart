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
import '../../../shared/widgets/loading_button.dart';
import '../../auth/data/auth_repository.dart';
import '../data/pantry_repository.dart';

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
  late final TextEditingController _quantity;
  late final TextEditingController _threshold;
  late String _unit;
  String? _category;
  DateTime? _expiryDate;
  bool _loading = false;
  String? _error;

  bool get isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item?.name ?? '');
    _quantity = TextEditingController(
      text: widget.item?.quantity.toString() ?? '',
    );
    _threshold = TextEditingController(
      text: widget.item?.lowStockThreshold?.toString() ?? '',
    );
    _unit = widget.item?.unit ?? 'kg';
    _category = widget.item?.category;
    _expiryDate = widget.item?.expiryDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _threshold.dispose();
    super.dispose();
  }

  Future<void> _save() async {
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

      final item = PantryItem(
        id: widget.item?.id ?? '',
        householdId: householdId,
        name: _name.text.trim(),
        quantity: double.parse(_quantity.text.trim()),
        unit: _unit,
        lowStockThreshold: _threshold.text.trim().isEmpty
            ? null
            : double.parse(_threshold.text.trim()),
        category: _category,
        expiryDate: _expiryDate,
      );

      if (isEditing) {
        await ref.read(pantryRepositoryProvider).updateItem(item);
      } else {
        await ref.read(pantryRepositoryProvider).createItem(item, householdId);
      }

      ref.invalidate(pantryItemsProvider);
      ref.invalidate(lowStockItemsProvider);
      ref.invalidate(expiringItemsProvider);
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _name,
                  label: AppStrings.itemName,
                  validator: Validators.required,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _quantity,
                  label: AppStrings.quantity,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: Validators.positiveNumber,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _unit,
                  decoration: const InputDecoration(labelText: AppStrings.unit),
                  items: PantryUnits.values
                      .map((u) => DropdownMenuItem(
                            value: u,
                            child: Text(PantryUnits.displayLabel(u)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _unit = v ?? 'kg'),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _threshold,
                  label: AppStrings.lowStockAlert,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(labelText: AppStrings.category),
                  items: PantryCategories.values
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(AppStrings.expiryDate),
                  subtitle: Text(
                    _expiryDate == null
                        ? 'Not set'
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
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 24),
                LoadingButton(
                  label: AppStrings.save,
                  isLoading: _loading,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
