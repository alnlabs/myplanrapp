class PantryUnits {
  PantryUnits._();

  static const values = ['g', 'kg', 'ml', 'L', 'pcs', 'pack'];

  static String label(String unit) {
    return switch (unit) {
      'g' => 'g',
      'kg' => 'kg',
      'ml' => 'ml',
      'L' => 'L',
      'pcs' => 'pcs',
      'pack' => 'pack',
      _ => unit,
    };
  }

  static String displayLabel(String unit) {
    return switch (unit) {
      'g' => 'grams (g)',
      'kg' => 'kilograms (kg)',
      'ml' => 'milliliters (ml)',
      'L' => 'liters (L)',
      'pcs' => 'pieces',
      'pack' => 'pack',
      _ => unit,
    };
  }
}

class PantryCategories {
  PantryCategories._();

  static const values = [
    'Grains',
    'Pulses',
    'Spices',
    'Dairy',
    'Vegetables',
    'Fruits',
    'Oils',
    'Snacks',
    'Household',
    'Other',
  ];
}
