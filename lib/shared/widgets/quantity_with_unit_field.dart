import 'package:flutter/material.dart';

import '../constants/pantry_constants.dart';

class QuantityWithUnitField extends StatelessWidget {
  const QuantityWithUnitField({
    super.key,
    required this.controller,
    required this.label,
    required this.unit,
    this.onUnitChanged,
    this.unitOptions,
    this.validator,
    this.readOnlyUnit = false,
  });

  final TextEditingController controller;
  final String label;
  final String unit;
  final ValueChanged<String>? onUnitChanged;
  final List<String>? unitOptions;
  final String? Function(String?)? validator;
  final bool readOnlyUnit;

  @override
  Widget build(BuildContext context) {
    final options = unitOptions ?? PantryUnits.values;
    final resolvedUnit = options.contains(unit) ? unit : options.first;

    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: readOnlyUnit || onUnitChanged == null
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      PantryUnits.label(resolvedUnit),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: resolvedUnit,
                    borderRadius: BorderRadius.circular(12),
                    items: options
                        .map(
                          (u) => DropdownMenuItem(
                            value: u,
                            child: Text(PantryUnits.label(u)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => onUnitChanged?.call(v ?? resolvedUnit),
                  ),
                ),
        ),
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }
}
