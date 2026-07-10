import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings/app_strings.dart';
import '../providers/list_display_mode_provider.dart';

/// Grid/list toggle for screens that support both layouts.
class ListDisplayModeToggle extends ConsumerWidget {
  const ListDisplayModeToggle({
    super.key,
    required this.screenKey,
    this.compact = false,
  });

  final String screenKey;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(listDisplayModeProvider(screenKey));

    return IconButton(
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      padding: compact ? EdgeInsets.zero : null,
      constraints: compact
          ? const BoxConstraints(minWidth: 32, minHeight: 32)
          : null,
      icon: Icon(
        mode == ListDisplayMode.grid
            ? Icons.view_list_outlined
            : Icons.grid_view_outlined,
        size: compact ? 20 : 24,
      ),
      tooltip: mode == ListDisplayMode.grid
          ? AppStrings.viewList
          : AppStrings.viewGrid,
      onPressed: () =>
          ref.read(listDisplayModeProvider(screenKey).notifier).toggle(),
    );
  }
}
