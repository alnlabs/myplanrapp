import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/models/recipe.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../pantry/data/pantry_repository.dart';
import '../../shopping/data/shopping_repository.dart';
import '../data/recipe_repository.dart';
import 'recipe_form_screen.dart';

class RecipesScreen extends ConsumerWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.recipesTitle),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const RecipeFormScreen()),
              );
              ref.invalidate(recipesProvider);
            },
            icon: const Icon(Icons.add),
            tooltip: AppStrings.addRecipe,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recipesProvider);
          await ref.read(recipesProvider.future);
        },
        child: AsyncScreenBody(
          value: recipesAsync,
          onRetry: () => ref.invalidate(recipesProvider),
          isEmpty: (recipes) => recipes.isEmpty,
          emptyTitle: AppStrings.emptyRecipes,
          emptySubtitle: AppStrings.emptyRecipesHint,
          emptyActionLabel: AppStrings.addRecipe,
          onEmptyAction: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const RecipeFormScreen()),
          ),
          builder: (recipes) {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: recipes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return Card(
                  child: ListTile(
                    title: Text(recipe.name),
                    subtitle: Text(
                      '${recipe.servings} ${AppStrings.servings.toLowerCase()}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => RecipeDetailScreen(recipe: recipe),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class RecipeDetailScreen extends ConsumerStatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipe});

  final Recipe recipe;

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  final _checkKey = GlobalKey();
  late int _targetServings;
  bool _cooking = false;

  @override
  void initState() {
    super.initState();
    _targetServings = widget.recipe.servings;
  }

  double get _scale => _targetServings / widget.recipe.servings;

  _ScaledStatus _scaledStatus(RecipeAvailability row) {
    final needed = row.requiredQuantity * _scale;
    if (row.availableQuantity <= 0) return _ScaledStatus.missing;
    if (row.availableQuantity < needed) return _ScaledStatus.insufficient;
    return _ScaledStatus.sufficient;
  }

  Future<void> _cookAndDeduct() async {
    final availability =
        await ref.read(recipeAvailabilityProvider(widget.recipe.id).future);
    final canCook = availability.every(
      (r) => _scaledStatus(r) == _ScaledStatus.sufficient,
    );
    if (!canCook) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not all ingredients are available')),
      );
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.cookAndDeduct),
        content: Text(
          'Update pantry for $_targetServings ${AppStrings.servings.toLowerCase()}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _cooking = true);
    try {
      await ref.read(recipeRepositoryProvider).cookAndDeduct(
            widget.recipe.id,
            scale: _scale,
          );
      ref.invalidate(pantryItemsProvider);
      ref.invalidate(lowStockItemsProvider);
      ref.invalidate(recipeAvailabilityProvider(widget.recipe.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pantry updated after cooking')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorFormatter.format(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _cooking = false);
    }
  }

  Future<void> _deleteRecipe() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.delete),
        content: const Text(AppStrings.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(recipeRepositoryProvider).deleteRecipe(widget.recipe.id);
    ref.invalidate(recipesProvider);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.recipeDeleted)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final availabilityAsync =
        ref.watch(recipeAvailabilityProvider(widget.recipe.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.name),
        actions: [
          IconButton(
            onPressed: () async {
              final latest = await ref
                  .read(recipeRepositoryProvider)
                  .fetchRecipe(widget.recipe.id);
              if (!context.mounted) return;
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RecipeFormScreen(recipe: latest),
                ),
              );
              ref.invalidate(recipesProvider);
              ref.invalidate(recipeAvailabilityProvider(widget.recipe.id));
            },
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: _deleteRecipe,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.recipe.instructions != null &&
              widget.recipe.instructions!.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(widget.recipe.instructions!),
              ),
            ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.scaleServings,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('${AppStrings.cookingFor}:'),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: _targetServings > 1
                            ? () => setState(() => _targetServings--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$_targetServings',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        onPressed: () => setState(() => _targetServings++),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                      const Spacer(),
                      Text(
                        'Recipe: ${widget.recipe.servings}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () {
              Scrollable.ensureVisible(
                _checkKey.currentContext!,
                duration: const Duration(milliseconds: 300),
              );
            },
            icon: const Icon(Icons.restaurant_menu_outlined),
            label: const Text(AppStrings.cookCheck),
          ),
          const SizedBox(height: 8),
          LoadingButton(
            label: AppStrings.cookAndDeduct,
            isLoading: _cooking,
            icon: Icons.soup_kitchen_outlined,
            onPressed: _cookAndDeduct,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.cookCheckResults,
            key: _checkKey,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          AsyncScreenBody(
            value: availabilityAsync,
            onRetry: () =>
                ref.invalidate(recipeAvailabilityProvider(widget.recipe.id)),
            builder: (rows) {
              return Column(
                children: [
                  ...rows.map((row) {
                    final status = _scaledStatus(row);
                    final needed = row.requiredQuantity * _scale;
                    final chipType = switch (status) {
                      _ScaledStatus.sufficient => StatusChipType.sufficient,
                      _ScaledStatus.insufficient => StatusChipType.insufficient,
                      _ScaledStatus.missing => StatusChipType.missing,
                    };
                    return Card(
                      child: ListTile(
                        title: Text(row.ingredientName),
                        subtitle: Text(
                          'Need ${Formatters.quantity(needed, row.unit)} · '
                          'Have ${Formatters.quantity(row.availableQuantity, row.unit)}',
                        ),
                        trailing: StatusChip(type: chipType),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await ref
                            .read(shoppingRepositoryProvider)
                            .generateFromRecipe(widget.recipe.id);
                        ref.invalidate(shoppingListProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Added missing items to shop list'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ApiErrorFormatter.format(e)),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text(AppStrings.addMissingToShop),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

enum _ScaledStatus { sufficient, insufficient, missing }
