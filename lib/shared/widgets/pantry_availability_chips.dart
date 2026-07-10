import 'package:flutter/material.dart';

import '../../core/strings/app_strings.dart';
import '../constants/pantry_availability.dart';

class PantryAvailabilityChips extends StatelessWidget {
  const PantryAvailabilityChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = <({String value, String label})>[
      (value: PantryAvailability.fine, label: AppStrings.availabilityFine),
      (value: PantryAvailability.warning, label: AppStrings.availabilityWarning),
      (value: PantryAvailability.required, label: AppStrings.availabilityRequired),
      (value: PantryAvailability.emergency, label: AppStrings.availabilityEmergency),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.availabilitySection,
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        Text(
          AppStrings.availabilityHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected == option.value;
            final color = PantryAvailability.color(option.value);

            return ChoiceChip(
              label: Text(option.label),
              selected: isSelected,
              selectedColor: color.withOpacity(0.16),
              side: BorderSide(
                color: isSelected ? color : theme.colorScheme.outlineVariant,
              ),
              labelStyle: theme.textTheme.labelLarge?.copyWith(
                color: isSelected ? color : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              onSelected: (_) => onSelected(option.value),
            );
          }).toList(),
        ),
      ],
    );
  }
}
