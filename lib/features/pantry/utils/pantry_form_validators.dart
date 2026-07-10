import '../../../core/strings/app_strings.dart';
import '../../../shared/utils/validators.dart';

/// Validates pantry quantity based on whether manual availability is set.
String? validatePantryQuantity(
  String? value, {
  required bool hasAvailabilityStatus,
}) {
  if (value == null || value.trim().isEmpty) {
    return hasAvailabilityStatus ? null : AppStrings.pantryTrackingRequired;
  }
  return Validators.positiveNumber(value);
}
