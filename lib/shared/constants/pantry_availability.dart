import 'package:flutter/material.dart';

import '../../core/strings/app_strings.dart';

/// Manual pantry availability levels set by the household.
class PantryAvailability {
  PantryAvailability._();

  static const fine = 'fine';
  static const warning = 'warning';
  static const required = 'required';
  static const emergency = 'emergency';

  static const attention = [warning, required, emergency];
  static const all = [fine, warning, required, emergency];

  static String label(String? status) {
    return switch (status) {
      fine => AppStrings.availabilityFine,
      warning => AppStrings.availabilityWarning,
      required => AppStrings.availabilityRequired,
      emergency => AppStrings.availabilityEmergency,
      _ => AppStrings.availabilityAuto,
    };
  }

  static int severity(String? status) {
    return switch (status) {
      emergency => 1,
      required => 2,
      warning => 3,
      _ => 99,
    };
  }

  static Color color(String status) {
    return switch (status) {
      fine => Colors.green.shade800,
      emergency => Colors.red.shade800,
      required => Colors.deepOrange.shade800,
      warning => Colors.amber.shade900,
      _ => Colors.green.shade800,
    };
  }

  static Color background(String status) {
    return switch (status) {
      fine => Colors.green.shade50,
      emergency => Colors.red.shade50,
      required => Colors.deepOrange.shade50,
      warning => Colors.amber.shade50,
      _ => Colors.green.shade50,
    };
  }
}
