import 'package:flutter/material.dart';

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

  /// Unit family for cross-unit comparisons (mass, volume, count).
  static String family(String unit) {
    return switch (unit) {
      'g' || 'kg' => 'mass',
      'ml' || 'L' => 'volume',
      _ => 'count',
    };
  }

  /// Units that can be compared with (and converted to/from) [unit].
  static List<String> compatibleWith(String unit) {
    final fam = family(unit);
    return values.where((u) => family(u) == fam).toList();
  }

  /// Multiplier to convert [unit] to its family base (grams / ml / each).
  static num baseFactor(String unit) {
    return switch (unit) {
      'kg' || 'L' => 1000,
      _ => 1,
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

  static IconData iconFor(String? category) {
    return switch (category) {
      'Grains' => Icons.grass_outlined,
      'Pulses' => Icons.grain_outlined,
      'Spices' => Icons.local_fire_department_outlined,
      'Dairy' => Icons.egg_outlined,
      'Vegetables' => Icons.eco_outlined,
      'Fruits' => Icons.apple_outlined,
      'Oils' => Icons.water_drop_outlined,
      'Snacks' => Icons.cookie_outlined,
      'Household' => Icons.cleaning_services_outlined,
      _ => Icons.kitchen_outlined,
    };
  }
}
