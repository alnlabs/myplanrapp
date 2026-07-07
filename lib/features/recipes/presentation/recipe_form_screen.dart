import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/pantry_constants.dart';
import '../../../shared/models/pantry_item.dart';
import '../../../shared/models/recipe.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../auth/data/auth_repository.dart';
import '../../pantry/data/pantry_repository.dart';
import '../data/recipe_repository.dart';

class RecipeFormScreen extends ConsumerStatefulWidget {
  const RecipeFormScreen({super.key, this.recipe});

  final Recipe? recipe;

  @override
  ConsumerState<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends ConsumerState<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _servings;
  late final TextEditingController _instructions;
  late final List<_IngredientRow> _ingredients;
  bool _loading = false;
  String? _error;

  bool get isEditing => widget.recipe != null;

  @override
  void initState() {
    super.initState();
    final recipe = widget.recipe;
    _name = TextEditingController(text: recipe?.name ?? '');
    _servings = TextEditingController(text: '${recipe?.servings ?? 4}');
    _instructions = TextEditingController(text: recipe?.instructions ?? '');
    _ingredients = recipe != null && recipe.ingredients.isNotEmpty
        ? recipe.ingredients.map(_IngredientRow.fromIngredient).toList()
        : [_IngredientRow()];
  }

  @override
  void dispose() {
    _name.dispose();
    _servings.dispose();
    _instructions.dispose();
    for (final row in _ingredients) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await ref.read(userProfileProvider.future);
      final householdId = profile?.activeHouseholdId;
      if (householdId == null) throw Exception(AppStrings.noHousehold);

      final ingredients = _ingredients
          .where((r) => r.name.text.trim().isNotEmpty)
          .map(
            (r) => RecipeIngredient(
              name: r.name.text.trim(),
              quantity: double.parse(r.quantity.text.trim()),
              unit: r.unit,
              pantryItemId: r.pantryItem?.id ?? r.pantryItemId,
            ),
          )
          .toList();

      final repo = ref.read(recipeRepositoryProvider);
      if (isEditing) {
        await repo.updateRecipe(
          id: widget.recipe!.id,
          name: _name.text.trim(),
          servings: int.parse(_servings.text.trim()),
          instructions: _instructions.text.trim().isEmpty
              ? null
              : _instructions.text.trim(),
          ingredients: ingredients,
        );
      } else {
        await repo.createRecipe(
          householdId: householdId,
          name: _name.text.trim(),
          servings: int.parse(_servings.text.trim()),
          instructions: _instructions.text.trim().isEmpty
              ? null
              : _instructions.text.trim(),
          ingredients: ingredients,
        );
      }

      ref.invalidate(recipesProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = ApiErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pantryAsync = ref.watch(pantryItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? AppStrings.editRecipe : AppStrings.addRecipe),
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
                  label: AppStrings.recipeName,
                  validator: Validators.required,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _servings,
                  label: AppStrings.servings,
                  keyboardType: TextInputType.number,
                  validator: Validators.positiveNumber,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _instructions,
                  label: AppStrings.instructions,
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                Text(AppStrings.ingredients,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                pantryAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (pantryItems) {
                    return Column(
                      children: _ingredients.asMap().entries.map((entry) {
                        final index = entry.key;
                        final row = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: AppTextField(
                                      controller: row.name,
                                      label: AppStrings.ingredientName,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: AppTextField(
                                      controller: row.quantity,
                                      label: AppStrings.quantity,
                                      keyboardType: const TextInputType
                                          .numberWithOptions(decimal: true),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<String>(
                                      value: row.unit,
                                      decoration: const InputDecoration(
                                          labelText: AppStrings.unit),
                                      items: PantryUnits.values
                                          .map((u) => DropdownMenuItem(
                                              value: u, child: Text(u)))
                                          .toList(),
                                      onChanged: (v) =>
                                          setState(() => row.unit = v ?? 'g'),
                                    ),
                                  ),
                                  if (_ingredients.length > 1)
                                    IconButton(
                                      onPressed: () =>
                                          setState(() => _ingredients.removeAt(index)),
                                      icon: const Icon(Icons.close),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<PantryItem?>(
                                value: row.pantryItem,
                                decoration: const InputDecoration(
                                  labelText: AppStrings.linkPantryItem,
                                ),
                                items: [
                                  const DropdownMenuItem<PantryItem?>(
                                    value: null,
                                    child: Text('None'),
                                  ),
                                  ...pantryItems.map(
                                    (p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(p.name),
                                    ),
                                  ),
                                ],
                                onChanged: (v) => setState(() {
                                  row.pantryItem = v;
                                  if (v != null && row.name.text.isEmpty) {
                                    row.name.text = v.name;
                                  }
                                }),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _ingredients.add(_IngredientRow())),
                    icon: const Icon(Icons.add),
                    label: const Text(AppStrings.addIngredient),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
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

class _IngredientRow {
  _IngredientRow();

  factory _IngredientRow.fromIngredient(RecipeIngredient ingredient) {
    final row = _IngredientRow();
    row.name.text = ingredient.name;
    row.quantity.text = ingredient.quantity.toString();
    row.unit = ingredient.unit;
    row.pantryItemId = ingredient.pantryItemId;
    return row;
  }

  final name = TextEditingController();
  final quantity = TextEditingController();
  String unit = 'g';
  String? pantryItemId;
  PantryItem? pantryItem;

  void dispose() {
    name.dispose();
    quantity.dispose();
  }
}
