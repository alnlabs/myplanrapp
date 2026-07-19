/// Sensible increment per unit so quantity steppers/sliders snap to natural
/// amounts (1 for countable units, 0.5 for kg/L, 50 for g/ml).
double quantityStepForUnit(String unit) {
  return switch (unit) {
    'pcs' || 'pack' => 1,
    'kg' || 'L' => 0.5,
    'g' || 'ml' => 50,
    _ => 1,
  };
}

/// Formats a quantity without trailing zeros (e.g. 2, 2.5, 0.25).
String formatQuantity(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value
      .toStringAsFixed(2)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}
