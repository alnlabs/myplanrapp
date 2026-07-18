import 'package:flutter/material.dart';

/// Shared grid sizing for list screens (pantry, plans, expenses, etc.).
abstract final class ListGridLayout {
  static const crossAxisCount = 2;
  static const tabCrossAxisCount = 3;
  static const spacing = 8.0;
  static const mainAxisExtent = 128.0;
  static const padding = EdgeInsets.fromLTRB(16, 8, 16, 96);

  static const gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: crossAxisCount,
    mainAxisSpacing: spacing,
    crossAxisSpacing: spacing,
    mainAxisExtent: mainAxisExtent,
  );

  static const tabGridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: tabCrossAxisCount,
    mainAxisSpacing: spacing,
    crossAxisSpacing: spacing,
    mainAxisExtent: mainAxisExtent,
  );
}
