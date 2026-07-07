import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _seedColor = Color(0xFF0D9488);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );
    final textTheme = GoogleFonts.dmSansTextTheme();

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
      ),
    );
  }
}
