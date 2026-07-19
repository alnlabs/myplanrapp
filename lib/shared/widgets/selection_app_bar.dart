import 'package:flutter/material.dart';

import '../../core/strings/app_strings.dart';

/// A contextual app bar shown while a list is in multi-select mode.
/// Displays the selected count with select-all, delete and close actions.
class SelectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SelectionAppBar({
    super.key,
    required this.selectedCount,
    required this.totalCount,
    required this.onClose,
    required this.onSelectAll,
    required this.onDelete,
  });

  final int selectedCount;
  final int totalCount;
  final VoidCallback onClose;
  final VoidCallback onSelectAll;
  final VoidCallback onDelete;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final allSelected = selectedCount >= totalCount && totalCount > 0;
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: AppStrings.close,
        onPressed: onClose,
      ),
      title: Text(AppStrings.selectedCount(selectedCount)),
      actions: [
        IconButton(
          icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
          tooltip: allSelected ? AppStrings.deselectAll : AppStrings.selectAll,
          onPressed: onSelectAll,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: AppStrings.delete,
          onPressed: selectedCount == 0 ? null : onDelete,
        ),
      ],
    );
  }
}

/// Shared confirmation dialog for bulk deletes. Returns true on confirm.
Future<bool> confirmBulkDelete(BuildContext context, int count) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(AppStrings.deleteSelectedTitle),
      content: Text(AppStrings.deleteSelectedMessage(count)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(AppStrings.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(AppStrings.delete),
        ),
      ],
    ),
  );
  return result ?? false;
}
