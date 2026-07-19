import 'package:flutter/material.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/models/expense.dart';

/// A Personal/Household visibility toggle used by the money entry forms.
/// Personal rows are private to their creator; household rows are shared.
class ScopeSelector extends StatelessWidget {
  const ScopeSelector({
    super.key,
    required this.scope,
    required this.onChanged,
    this.enabled = true,
  });

  final MoneyScope scope;
  final ValueChanged<MoneyScope> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.scopeLabel,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<MoneyScope>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: const [
              ButtonSegment(
                value: MoneyScope.household,
                label: Text(AppStrings.scopeHousehold),
                icon: Icon(Icons.home_outlined),
              ),
              ButtonSegment(
                value: MoneyScope.personal,
                label: Text(AppStrings.scopePersonal),
                icon: Icon(Icons.lock_outline),
              ),
            ],
            selected: {scope},
            onSelectionChanged:
                enabled ? (selection) => onChanged(selection.first) : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          scope == MoneyScope.personal
              ? AppStrings.scopePersonalHint
              : AppStrings.scopeHouseholdHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
