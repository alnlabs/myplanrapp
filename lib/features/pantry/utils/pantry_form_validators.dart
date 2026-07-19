import '../../../shared/utils/validators.dart';

/// The exact amount is independent of the color availability label — an item can
/// track a precise quantity, a color status, or both. So quantity is always
/// optional and only validated for format when provided.
String? validatePantryQuantity(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return Validators.positiveNumber(value);
}
