import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/utils/app_bottom_sheet.dart';
import '../../assets/presentation/asset_form_screen.dart';
import '../../assistant/presentation/scan_receipt_screen.dart';
import '../../expenses/presentation/add_expense_screen.dart';
import '../../reminders/presentation/medicine_reminder_form_screen.dart';
import '../../reminders/presentation/reminder_form_screen.dart';

/// Opens the central "Add" sheet listing every create action (plus scanner).
Future<void> showAddSheet(BuildContext context) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AddSheet(originContext: context),
  );
}

class _AddSheet extends StatelessWidget {
  const _AddSheet({required this.originContext});

  /// Context from the screen that opened the sheet, used for navigation after
  /// the sheet is dismissed.
  final BuildContext originContext;

  void _run(BuildContext sheetContext, VoidCallback action) {
    Navigator.of(sheetContext).pop();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actions = <_AddAction>[
      _AddAction(
        icon: Icons.payments_outlined,
        label: AppStrings.addExpense,
        onTap: () => Navigator.of(originContext).push(
          MaterialPageRoute<void>(builder: (_) => const AddExpenseScreen()),
        ),
      ),
      _AddAction(
        icon: Icons.event_note_outlined,
        label: AppStrings.addPlan,
        onTap: () => originContext.push('/plans/add'),
      ),
      _AddAction(
        icon: Icons.restaurant_outlined,
        label: AppStrings.addMeal,
        onTap: () => originContext.push('/plans/add?type=meal&slot=lunch'),
      ),
      _AddAction(
        icon: Icons.notifications_outlined,
        label: AppStrings.addReminder,
        onTap: () => Navigator.of(originContext).push(
          MaterialPageRoute<void>(builder: (_) => const ReminderFormScreen()),
        ),
      ),
      _AddAction(
        icon: Icons.medication_outlined,
        label: AppStrings.addMedicine,
        onTap: () => Navigator.of(originContext).push(
          MaterialPageRoute<void>(
            builder: (_) => const MedicineReminderFormScreen(),
          ),
        ),
      ),
      _AddAction(
        icon: Icons.kitchen_outlined,
        label: AppStrings.addItem,
        onTap: () => originContext.push('/pantry/add'),
      ),
      _AddAction(
        icon: Icons.inventory_2_outlined,
        label: AppStrings.addAsset,
        onTap: () => Navigator.of(originContext).push(
          MaterialPageRoute<void>(builder: (_) => const AssetFormScreen()),
        ),
      ),
      _AddAction(
        icon: Icons.subscriptions_outlined,
        label: AppStrings.addSubscription,
        onTap: () => originContext.push('/subscriptions/add'),
      ),
      _AddAction(
        icon: Icons.shopping_cart_outlined,
        label: AppStrings.addShoppingItem,
        onTap: () => originContext.push('/shop'),
      ),
      _AddAction(
        icon: Icons.receipt_long_outlined,
        label: AppStrings.assistantTitle,
        onTap: () => Navigator.of(originContext).push(
          MaterialPageRoute<void>(builder: (_) => const ScanReceiptScreen()),
        ),
      ),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text(
                AppStrings.addSheetTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return _AddTile(
                  action: action,
                  onTap: () => _run(context, action.onTap),
                );
              },
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _AddAction {
  const _AddAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.action, required this.onTap});

  final _AddAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(action.icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 6),
          Text(
            action.label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
