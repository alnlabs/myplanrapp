import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/api_error_formatter.dart';
import 'empty_state.dart';
import 'error_view.dart';

class AsyncScreenBody<T> extends StatelessWidget {
  const AsyncScreenBody({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
    this.isEmpty,
    this.emptyIcon,
    this.emptyTitle,
    this.emptySubtitle,
    this.emptyActionLabel,
    this.onEmptyAction,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final bool Function(T data)? isEmpty;
  final IconData? emptyIcon;
  final String? emptyTitle;
  final String? emptySubtitle;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorView(
        error: error,
        message: ApiErrorFormatter.format(error),
        onRetry: onRetry,
      ),
      data: (data) {
        if (isEmpty != null && isEmpty!(data) && emptyTitle != null) {
          return EmptyState(
            icon: emptyIcon ?? Icons.inbox_outlined,
            title: emptyTitle!,
            subtitle: emptySubtitle,
            actionLabel: emptyActionLabel,
            onAction: onEmptyAction,
          );
        }
        return builder(data);
      },
    );
  }
}
