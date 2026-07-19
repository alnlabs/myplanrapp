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
        // A compact single-choice dropdown; each level carries its own color so
        // the meaning is clear both in the list and once selected.
        DropdownButtonFormField<String>(
          value: selected,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: options.map((option) {
            final color = PantryAvailability.color(option.value);
            return DropdownMenuItem<String>(
              value: option.value,
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    option.label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onSelected,
        ),
      ],
    );
  }
}
