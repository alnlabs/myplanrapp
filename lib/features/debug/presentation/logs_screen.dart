import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/strings/app_strings.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  Future<void> _copyAll(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: AppLogger.instance.exportText()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.logsCopied)),
      );
    }
  }

  Future<void> _clear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.logsClearTitle),
        content: const Text(AppStrings.logsClearBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AppLogger.instance.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.logsTitle),
        actions: [
          IconButton(
            tooltip: AppStrings.logsCopy,
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: () => _copyAll(context),
          ),
          IconButton(
            tooltip: AppStrings.logsClear,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _clear(context),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<LogEntry>>(
        valueListenable: AppLogger.instance.entries,
        builder: (context, entries, _) {
          if (entries.isEmpty) {
            return const Center(child: Text(AppStrings.logsEmpty));
          }
          // Newest first.
          final ordered = entries.reversed.toList();
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: ordered.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) => _LogTile(entry: ordered[index]),
          );
        },
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.entry});

  final LogEntry entry;

  Color _color(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (entry.level) {
      case LogLevel.error:
        return scheme.error;
      case LogLevel.warning:
        return Colors.orange.shade800;
      case LogLevel.info:
        return scheme.primary;
      case LogLevel.debug:
        return scheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    final time = entry.time;
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    final ss = time.second.toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  entry.level.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$hh:$mm:$ss',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(
            entry.message,
            style: const TextStyle(fontSize: 13, height: 1.3),
          ),
          if (entry.error != null && entry.error!.isNotEmpty) ...[
            const SizedBox(height: 2),
            SelectableText(
              entry.error!,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ],
          if (entry.stackTrace != null && entry.stackTrace!.isNotEmpty) ...[
            const SizedBox(height: 2),
            SelectableText(
              entry.stackTrace!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
