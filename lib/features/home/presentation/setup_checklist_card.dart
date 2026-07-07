import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../expenses/presentation/add_expense_screen.dart';
import '../../household/presentation/household_screen.dart';
import '../data/setup_checklist_provider.dart';

class SetupChecklistCard extends ConsumerWidget {
  const SetupChecklistCard({super.key, required this.checklist});

  final SetupChecklist checklist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.setupChecklistTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: AppStrings.hideChecklist,
                  onPressed: () async {
                    await dismissSetupChecklist();
                    ref.invalidate(setupChecklistDismissedProvider);
                    ref.invalidate(setupChecklistProvider);
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.setupChecklistHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            _CheckItem(
              done: checklist.pantryDone,
              label: AppStrings.checklistPantry,
              onTap: () => context.push('/pantry/add'),
            ),
            _CheckItem(
              done: checklist.familyDone,
              label: AppStrings.checklistFamily,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const HouseholdScreen()),
              ),
            ),
            _CheckItem(
              done: checklist.planDone,
              label: AppStrings.checklistPlan,
              onTap: () => context.push('/plans/add'),
            ),
            _CheckItem(
              done: checklist.expenseDone,
              label: AppStrings.checklistExpense,
              optional: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AddExpenseScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  const _CheckItem({
    required this.done,
    required this.label,
    required this.onTap,
    this.optional = false,
  });

  final bool done;
  final String label;
  final VoidCallback onTap;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(
        done ? Icons.check_circle : Icons.radio_button_unchecked,
        color: done
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline,
      ),
      title: Text(label),
      subtitle: optional ? const Text(AppStrings.optional) : null,
      trailing: done ? null : const Icon(Icons.chevron_right, size: 20),
      onTap: done ? null : onTap,
    );
  }
}
