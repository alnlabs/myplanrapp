import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class TypeScale {
  static const appBarTitle = 20.0;
  static const sheetTitle = 17.0;
  static const emptyStateTitle = 17.0;
  static const sectionTitle = 13.0;
  static const cardTitle = 14.0;
}

abstract final class AppTypography {
  static TextStyle appBarTitle(BuildContext context) {
    return GoogleFonts.dmSans(
      fontSize: TypeScale.appBarTitle,
      fontWeight: FontWeight.w600,
      height: 1.15,
      letterSpacing: -0.3,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle emptyStateTitle(BuildContext context) {
    return GoogleFonts.dmSans(
      fontSize: TypeScale.emptyStateTitle,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle sectionTitle(BuildContext context) {
    return GoogleFonts.dmSans(
      fontSize: TypeScale.sectionTitle,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  static TextStyle cardTitle(BuildContext context) {
    return GoogleFonts.dmSans(
      fontSize: TypeScale.cardTitle,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }
}
