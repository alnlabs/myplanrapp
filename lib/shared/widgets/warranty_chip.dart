import 'package:flutter/material.dart';

import '../../core/strings/app_strings.dart';
import '../constants/asset_constants.dart';

class WarrantyChip extends StatelessWidget {
  const WarrantyChip({super.key, required this.status});

  final WarrantyStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == WarrantyStatus.none) return const SizedBox.shrink();

    final (label, color, bg) = switch (status) {
      WarrantyStatus.valid => (
          AppStrings.warrantyValid,
          Colors.green.shade800,
          Colors.green.shade50,
        ),
      WarrantyStatus.expiring => (
          AppStrings.warrantyExpiring,
          Colors.amber.shade900,
          Colors.amber.shade50,
        ),
      WarrantyStatus.expired => (
          AppStrings.warrantyExpired,
          Colors.red.shade800,
          Colors.red.shade50,
        ),
      WarrantyStatus.none => ('', Colors.grey, Colors.grey),
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
}
