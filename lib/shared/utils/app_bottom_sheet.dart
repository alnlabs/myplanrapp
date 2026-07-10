import 'package:flutter/material.dart';

/// Shows a modal bottom sheet above the shell bottom navigation bar.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool showDragHandle = true,
  bool isScrollControlled = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    showDragHandle: showDragHandle,
    isScrollControlled: isScrollControlled,
    builder: builder,
  );
}
