import 'package:flutter/material.dart';

import '../../core/strings/app_strings.dart';
import '../constants/pantry_constants.dart';
import '../utils/app_bottom_sheet.dart';
import '../utils/quantity_step.dart';

/// Outcome of the restock-on-buy sheet.
class RestockSheetResult {
  const RestockSheetResult({required this.amount, required this.restock});

  /// Restock the pantry by [amount].
  const RestockSheetResult.restock(this.amount) : restock = true;

  /// Mark the item bought without touching pantry stock.
  const RestockSheetResult.skip()
      : amount = 0,
        restock = false;

  final double amount;
  final bool restock;
}

/// Asks the user how much of a bought shopping item was actually restocked into
/// the pantry. Returns null if dismissed/cancelled.
Future<RestockSheetResult?> showRestockAmountSheet({
  required BuildContext context,
  required String itemName,
  required String unit,
  double? suggestedAmount,
}) {
  final step = quantityStepForUnit(unit);
  var amount = (suggestedAmount != null && suggestedAmount > 0)
      ? suggestedAmount
      : step;

  return showAppBottomSheet<RestockSheetResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final theme = Theme.of(context);
          final unitLabel = PantryUnits.label(unit);

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
                  AppStrings.restockHowMuch,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  itemName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _RoundIconButton(
                      icon: Icons.remove,
                      onTap: amount <= step
                          ? null
                          : () => setSheetState(() => amount -= step),
                    ),
                    Expanded(
                      child: Text(
                        '${formatQuantity(amount)} $unitLabel',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _RoundIconButton(
                      icon: Icons.add,
                      onTap: () => setSheetState(() => amount += step),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${AppStrings.stepsOf} ${formatQuantity(step)} '
                  '${PantryUnits.displayLabel(unit)}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    RestockSheetResult.restock(amount),
                  ),
                  child: const Text(AppStrings.restockAddToPantry),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(
                    context,
                    const RestockSheetResult.skip(),
                  ),
                  child: const Text(AppStrings.restockSkip),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 48,
      height: 48,
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
