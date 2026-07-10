import 'package:flutter/material.dart';

import '../providers/paginated_list_state.dart';

/// Triggers [onLoadMore] when the user scrolls near the bottom.
class PaginatedScrollListener extends StatelessWidget {
  const PaginatedScrollListener({
    super.key,
    required this.onLoadMore,
    required this.child,
    this.threshold = 200,
  });

  final VoidCallback onLoadMore;
  final Widget child;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Ignore momentum/overscroll noise; load when user nears the end.
        if (notification is ScrollUpdateNotification &&
            notification.metrics.extentAfter < threshold) {
          onLoadMore();
        }
        return false;
      },
      child: child,
    );
  }
}

class PaginatedListFooter extends StatelessWidget {
  const PaginatedListFooter({
    super.key,
    required this.state,
    this.onRetryLoadMore,
  });

  final PaginatedListState<dynamic> state;
  final VoidCallback? onRetryLoadMore;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.error != null && state.items.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: TextButton(
            onPressed: onRetryLoadMore,
            child: const Text('Could not load more — try again'),
          ),
        ),
      );
    }
    return const SizedBox(height: 96);
  }
}
