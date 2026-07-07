import 'package:flutter/material.dart';

import '../../core/strings/app_strings.dart';

class FilterMenuOption<T> {
  const FilterMenuOption({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

/// A compact header filter: an icon+label button that opens a popup menu
/// with a checkmark on the active option. Used across list screens for a
/// uniform filtering pattern (instead of large in-body chip/segment buttons).
class FilterMenuButton<T> extends StatelessWidget {
  const FilterMenuButton({
    super.key,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  final T value;
  final List<FilterMenuOption<T>> options;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = options.firstWhere(
      (o) => o.value == value,
      orElse: () => options.first,
    );

    return PopupMenuButton<T>(
      tooltip: AppStrings.filter,
      onSelected: onSelected,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => options
          .map(
            (o) => PopupMenuItem<T>(
              value: o.value,
              child: Row(
                children: [
                  Icon(
                    o.icon ?? Icons.circle_outlined,
                    size: 20,
                    color: o.value == value
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(o.label)),
                  if (o.value == value)
                    Icon(
                      Icons.check,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
            ),
          )
          .toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_list, size: 20),
            const SizedBox(width: 6),
            Text(
              current.label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
