import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/models/pantry_item.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_button.dart';
import '../data/pantry_repository.dart';
import '../data/pantry_shop_refresh.dart';
import '../../../shared/utils/app_bottom_sheet.dart';

/// Shared bottom sheet for logging pantry usage / restock.
/// The pantry list itself lives in [InventoryScreen] (features/inventory).
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
  var clearAvailability = isRestock && item.availabilityStatus != null;

  showAppBottomSheet<void>(
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
                  if (isRestock && item.availabilityStatus != null) ...[
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(AppStrings.clearAvailabilityOnRestock),
                      value: clearAvailability,
                      onChanged: (value) =>
                          setSheetState(() => clearAvailability = value),
                    ),
                  ],
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
                        if (isRestock && clearAvailability) {
                          await ref
                              .read(pantryRepositoryProvider)
                              .updateAvailabilityStatus(item.id, null);
                        }
                        await refreshPantryAfterStockChange(ref);
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

void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(AppStrings.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(AppStrings.delete),
        ),
      ],
    ),
  );
}
