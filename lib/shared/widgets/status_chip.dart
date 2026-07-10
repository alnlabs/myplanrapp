import 'package:flutter/material.dart';

import '../../core/strings/app_strings.dart';

enum StatusChipType {
  sufficient,
  insufficient,
  missing,
  lowStock,
  outOfStock,
  availabilityWarning,
  availabilityRequired,
  availabilityEmergency,
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.type});

  final StatusChipType type;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (type) {
      StatusChipType.sufficient => (
          AppStrings.statusSufficient,
          Colors.green.shade800,
          Colors.green.shade50,
        ),
      StatusChipType.insufficient => (
          AppStrings.statusInsufficient,
          Colors.orange.shade900,
          Colors.orange.shade50,
        ),
      StatusChipType.missing => (
          AppStrings.statusMissing,
          Colors.red.shade800,
          Colors.red.shade50,
        ),
      StatusChipType.lowStock => (
          AppStrings.lowStock,
          Colors.amber.shade900,
          Colors.amber.shade50,
        ),
      StatusChipType.outOfStock => (
          AppStrings.outOfStock,
          Colors.red.shade800,
          Colors.red.shade50,
        ),
      StatusChipType.availabilityWarning => (
          AppStrings.availabilityWarning,
          Colors.amber.shade900,
          Colors.amber.shade50,
        ),
      StatusChipType.availabilityRequired => (
          AppStrings.availabilityRequired,
          Colors.deepOrange.shade800,
          Colors.deepOrange.shade50,
        ),
      StatusChipType.availabilityEmergency => (
          AppStrings.availabilityEmergency,
          Colors.red.shade800,
          Colors.red.shade50,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  static StatusChipType? forAvailability(String? status) {
    return switch (status) {
      'fine' => StatusChipType.sufficient,
      'warning' => StatusChipType.availabilityWarning,
      'required' => StatusChipType.availabilityRequired,
      'emergency' => StatusChipType.availabilityEmergency,
      _ => null,
    };
  }
}
