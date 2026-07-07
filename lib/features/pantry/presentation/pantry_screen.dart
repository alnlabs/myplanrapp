import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/models/pantry_item.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/pantry_repository.dart';
import 'pantry_item_detail_screen.dart';

class PantryScreen extends ConsumerStatefulWidget {
  const PantryScreen({super.key});

  @override
  ConsumerState<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends ConsumerState<PantryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(pantryItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.pantryTitle),
        actions: [
          IconButton(
            onPressed: () async {
              await context.push('/pantry/add');
              ref.invalidate(pantryItemsProvider);
              ref.invalidate(lowStockItemsProvider);
            },
            icon: const Icon(Icons.add),
            tooltip: AppStrings.addItem,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: AppStrings.search,
              ),
              onChanged: (value) => setState(() => _query = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(pantryItemsProvider);
                await ref.read(pantryItemsProvider.future);
              },
              child: AsyncScreenBody(
                value: itemsAsync,
                onRetry: () => ref.invalidate(pantryItemsProvider),
                isEmpty: (items) => _filter(items).isEmpty,
                emptyTitle: AppStrings.emptyPantry,
                emptySubtitle: AppStrings.emptyPantryHint,
                emptyActionLabel: AppStrings.addItem,
                onEmptyAction: () => context.push('/pantry/add'),
                builder: (items) {
                  final filtered = _filter(items);
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _PantryItemCard(
                        item: item,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PantryItemDetailScreen(item: item),
                            ),
                          );
                          ref.invalidate(pantryItemsProvider);
                          ref.invalidate(lowStockItemsProvider);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PantryItem> _filter(List<PantryItem> items) {
    if (_query.isEmpty) return items;
    return items
        .where((i) =>
            i.name.toLowerCase().contains(_query) ||
            (i.category?.toLowerCase().contains(_query) ?? false))
        .toList();
  }
}

class _PantryItemCard extends StatelessWidget {
  const _PantryItemCard({required this.item, required this.onTap});

  final PantryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(item.name),
        subtitle: Text(Formatters.quantity(item.quantity, item.unit)),
        trailing: item.isOutOfStock
            ? const StatusChip(type: StatusChipType.outOfStock)
            : item.isLowStock
                ? const StatusChip(type: StatusChipType.lowStock)
                : null,
      ),
    );
  }
}

void showStockSheet(
  BuildContext context,
  WidgetRef ref, {
  required PantryItem item,
  required bool isRestock,
}) {
  final qtyController = TextEditingController();
  final noteController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var loading = false;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isRestock ? AppStrings.restockItem : AppStrings.useItem,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: qtyController,
                    label: AppStrings.quantity,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: Validators.positiveNumber,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: noteController,
                    label: AppStrings.note,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  LoadingButton(
                    label: AppStrings.save,
                    isLoading: loading,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      setSheetState(() => loading = true);
                      try {
                        final qty = double.parse(qtyController.text.trim());
                        await ref.read(pantryRepositoryProvider).applyStockEvent(
                              itemId: item.id,
                              delta: isRestock ? qty : -qty,
                              reason: isRestock ? 'restocked' : 'used',
                              note: noteController.text.trim().isEmpty
                                  ? null
                                  : noteController.text.trim(),
                            );
                        ref.invalidate(pantryItemsProvider);
                        ref.invalidate(lowStockItemsProvider);
                        ref.invalidate(stockEventsProvider(item.id));
                        if (context.mounted) {
                          Navigator.pop(context);
                          showSuccessSnackBar(context, AppStrings.stockUpdated);
                        }
                      } finally {
                        if (context.mounted) setSheetState(() => loading = false);
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
