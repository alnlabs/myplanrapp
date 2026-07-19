import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/providers/multi_select_provider.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/blocking_progress.dart';
import '../../../shared/widgets/selection_app_bar.dart';
import '../data/assistant_repository.dart';
import '../data/models/saved_receipt.dart';

/// History of receipts saved via scan or paste.
class ReceiptsListScreen extends ConsumerWidget {
  const ReceiptsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsAsync = ref.watch(savedReceiptsProvider);
    final receipts = receiptsAsync.valueOrNull ?? const <SavedReceipt>[];
    final selection = ref.watch(multiSelectProvider(MultiSelectKeys.receipts));
    final notifier =
        ref.read(multiSelectProvider(MultiSelectKeys.receipts).notifier);

    return Scaffold(
      appBar: selection.active
          ? SelectionAppBar(
              selectedCount: selection.count,
              totalCount: receipts.length,
              onClose: notifier.clear,
              onSelectAll: () {
                if (selection.count >= receipts.length) {
                  notifier.selectAll(const []);
                } else {
                  notifier.selectAll(receipts.map((e) => e.id));
                }
              },
              onDelete: () => _deleteSelected(context, ref),
            )
          : AppBar(title: const Text(AppStrings.receiptsTitle)),
      body: SafeArea(
        child: receiptsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text(AppStrings.errorGeneric)),
          data: (receipts) {
            if (receipts.isEmpty) {
              return _EmptyState();
            }
            return RefreshIndicator(
              onRefresh: () async => ref.refresh(savedReceiptsProvider.future),
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: receipts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _ReceiptCard(receipt: receipts[i]),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _deleteSelected(BuildContext context, WidgetRef ref) async {
    final notifier =
        ref.read(multiSelectProvider(MultiSelectKeys.receipts).notifier);
    final ids =
        ref.read(multiSelectProvider(MultiSelectKeys.receipts)).ids.toList();
    if (ids.isEmpty) return;
    final confirmed = await confirmBulkDelete(context, ids.length);
    if (!confirmed || !context.mounted) return;
    final repo = ref.read(assistantRepositoryProvider);
    try {
      await runWithBlockingProgress(context, () => repo.deleteReceipts(ids));
      notifier.clear();
      ref.invalidate(savedReceiptsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.itemsDeleted(ids.length))),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.errorGeneric)),
        );
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              AppStrings.receiptsEmpty,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptCard extends ConsumerWidget {
  const _ReceiptCard({required this.receipt});

  final SavedReceipt receipt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final title = receipt.merchant?.trim().isNotEmpty == true
        ? receipt.merchant!.trim()
        : AppStrings.receiptsUnknownMerchant;
    final dateLabel =
        Formatters.date(receipt.purchasedAt ?? receipt.createdAt ?? DateTime.now());

    final selection = ref.watch(multiSelectProvider(MultiSelectKeys.receipts));
    final notifier =
        ref.read(multiSelectProvider(MultiSelectKeys.receipts).notifier);
    final selecting = selection.active;
    final selected = selection.contains(receipt.id);

    return Card(
      margin: EdgeInsets.zero,
      color: selected ? theme.colorScheme.primaryContainer : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: selecting
            ? Checkbox(
                value: selected,
                onChanged: (_) => notifier.toggle(receipt.id),
              )
            : null,
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '$dateLabel  ·  ${receipt.itemCount} ${AppStrings.receiptsItemsCount}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (receipt.total != null)
              Text(
                Formatters.currency(receipt.total!),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            const SizedBox(height: 4),
            _StatusBadge(processed: receipt.isProcessed),
          ],
        ),
        onTap: selecting
            ? () => notifier.toggle(receipt.id)
            : () => _showLines(context, ref),
        onLongPress: selecting ? null : () => notifier.enter(receipt.id),
      ),
    );
  }

  Future<void> _showLines(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReceiptLinesSheet(receipt: receipt),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.processed});

  final bool processed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        processed ? theme.colorScheme.primary : Colors.orange.shade800;
    final label =
        processed ? AppStrings.receiptsProcessed : AppStrings.receiptsPending;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ReceiptLinesSheet extends ConsumerWidget {
  const _ReceiptLinesSheet({required this.receipt});

  final SavedReceipt receipt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final linesAsync = ref.watch(_receiptLinesProvider(receipt.id));
    final title = receipt.merchant?.trim().isNotEmpty == true
        ? receipt.merchant!.trim()
        : AppStrings.receiptsUnknownMerchant;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              Formatters.date(
                  receipt.purchasedAt ?? receipt.createdAt ?? DateTime.now()),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 24),
            Expanded(
              child: linesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) =>
                    const Center(child: Text(AppStrings.errorGeneric)),
                data: (lines) {
                  if (lines.isEmpty) {
                    return const Center(
                        child: Text(AppStrings.receiptsNoLines));
                  }
                  return ListView.builder(
                    controller: controller,
                    itemCount: lines.length,
                    itemBuilder: (_, i) => _lineTile(theme, lines[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lineTile(ThemeData theme, Map<String, dynamic> line) {
    final name = (line['name'] as String?)?.trim();
    final qty = line['qty'];
    final unit = line['unit'] as String?;
    final destination = line['destination'] as String? ?? 'pantry';
    final applied = line['applied_at'] != null;
    final qtyLabel = qty == null ? '' : '$qty ${unit ?? ''}'.trim();

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        applied ? Icons.check_circle : Icons.radio_button_unchecked,
        color: applied
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
        size: 20,
      ),
      title: Text(name?.isNotEmpty == true ? name! : 'Item'),
      subtitle: qtyLabel.isEmpty ? null : Text(qtyLabel),
      trailing: Text(
        destination,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

final _receiptLinesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, receiptId) {
  return ref.watch(assistantRepositoryProvider).fetchReceiptLines(receiptId);
});
