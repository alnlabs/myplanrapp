import 'package:flutter/material.dart';

/// Runs [action] while showing a non-dismissible progress overlay, so the user
/// can't fire the operation twice. Always removes the overlay when done.
Future<T> runWithBlockingProgress<T>(
  BuildContext context,
  Future<T> Function() action,
) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );
  try {
    return await action();
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
