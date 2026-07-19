import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/pantry_constants.dart';
import '../../../shared/models/pantry_item.dart';
import '../../../shared/utils/quantity_step.dart';
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
  final noteController = TextEditingController();
  final available = item.quantity;
  final step = quantityStepForUnit(item.unit);
  // "Use" reduces stock and can never exceed what's on hand.
  var amount = isRestock
      ? step
      : (available >= step ? step : available);
  var loading = false;
  var clearAvailability = isRestock && item.availabilityStatus != null;

  showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final theme = Theme.of(context);
          final unitLabel = PantryUnits.label(item.unit);
          final remaining = (available - amount).clamp(0.0, double.infinity);
          final nothingToUse = !isRestock && available <= 0;
          final canSubmit =
              amount > 0 && (isRestock || amount <= available) && !nothingToUse;

          void setAmount(double value) {
            final upper = isRestock ? double.infinity : available;
            setSheetState(
              () => amount = value.clamp(0.0, upper).toDouble(),
            );
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isRestock ? AppStrings.restockItem : AppStrings.useItem,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  isRestock
                      ? item.name
                      : '${AppStrings.available}: ${formatQuantity(available)} $unitLabel',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                if (nothingToUse)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      AppStrings.nothingToUse,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      // "Use" only reduces, so it shows just the minus button;
                      // "Restock" only increases, so it shows just the plus.
                      if (!isRestock)
                        _StepButton(
                          icon: Icons.remove,
                          onTap: amount <= 0
                              ? null
                              : () => setAmount(amount - step),
                        )
                      else
                        const SizedBox(width: _kStepButtonSize),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${formatQuantity(amount)} $unitLabel',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (!isRestock)
                              Text(
                                '${AppStrings.remaining}: '
                                '${formatQuantity(remaining.toDouble())} $unitLabel',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isRestock)
                        _StepButton(
                          icon: Icons.add,
                          onTap: () => setAmount(amount + step),
                        )
                      else
                        const SizedBox(width: _kStepButtonSize),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${AppStrings.stepsOf} ${formatQuantity(step)} '
                    '${PantryUnits.displayLabel(item.unit)}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (!isRestock && available > 0) ...[
                    Slider(
                      value: amount.clamp(0.0, available).toDouble(),
                      max: available,
                      divisions: _sliderDivisions(available, step),
                      label: formatQuantity(amount),
                      onChanged: (value) => setAmount(_snap(value, step)),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setAmount(available),
                        child: const Text(AppStrings.useAll),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: noteController,
                    label: AppStrings.note,
                    maxLines: 2,
                  ),
                ],
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
                  onPressed: !canSubmit
                      ? null
                      : () async {
                          setSheetState(() => loading = true);
                          try {
                            await ref
                                .read(pantryRepositoryProvider)
                                .applyStockEvent(
                                  itemId: item.id,
                                  delta: isRestock ? amount : -amount,
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
                            // Refresh the item + caches; run list/shop sync in
                            // the background so the sheet closes right away.
                            ref.invalidate(pantryItemProvider(item.id));
                            ref.invalidate(stockEventsProvider(item.id));
                            unawaited(refreshPantryAfterStockChange(ref));
                            if (context.mounted) {
                              Navigator.pop(context);
                              showSuccessSnackBar(
                                  context, AppStrings.stockUpdated);
                            }
                          } finally {
                            if (context.mounted) {
                              setSheetState(() => loading = false);
                            }
                          }
                        },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// Slider divisions bounded so fractional units still snap to [step].
int? _sliderDivisions(double available, double step) {
  if (available <= 0 || step <= 0) return null;
  final count = (available / step).round();
  if (count < 1) return null;
  return count > 100 ? 100 : count;
}

double _snap(double value, double step) {
  if (step <= 0) return value;
  return (value / step).round() * step;
}

const double _kStepButtonSize = 48;

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: _kStepButtonSize,
      height: _kStepButtonSize,
      child: IconButton.filledTonal(
        onPressed: onTap,
        icon: Icon(icon),
        iconSize: 22,
        style: IconButton.styleFrom(
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }
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
