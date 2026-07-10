import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/shell_navigation.dart';

/// App bar with a compact title and optional subtitle for feature screens.
class FeatureScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FeatureScreenAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBackToMore = false,
    this.implyLeading = true,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBackToMore;

  /// When false, no back arrow is shown (e.g. root tab screens).
  final bool implyLeading;

  @override
  Size get preferredSize => Size.fromHeight(subtitle != null ? 64 : kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;

    return AppBar(
      automaticallyImplyLeading: implyLeading && !showBackToMore,
      leading: showBackToMore
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/more'),
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: hasSubtitle ? 18 : null,
              height: hasSubtitle ? 1.15 : null,
            ),
          ),
          if (hasSubtitle)
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      actions: actions,
      toolbarHeight: preferredSize.height,
    );
  }

  factory FeatureScreenAppBar.forShellRoute(
    BuildContext context, {
    required String title,
    String? subtitle,
    List<Widget>? actions,
  }) {
    return FeatureScreenAppBar(
      title: title,
      subtitle: subtitle,
      actions: actions,
      showBackToMore: openedFromMore(context),
      implyLeading: false,
    );
  }
}
