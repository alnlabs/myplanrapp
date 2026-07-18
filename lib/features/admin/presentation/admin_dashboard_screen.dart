import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../../auth/data/auth_repository.dart';
import '../data/admin_gate_provider.dart';
import '../data/admin_repository.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.signOutConfirmTitle),
        content: const Text(AppStrings.signOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(AppStrings.signOut),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    // OTP verification lasts for the whole signed-in session, so only clear it
    // on an explicit sign-out.
    ref.read(adminGateProvider.notifier).reset();
    await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dedicated admin-only accounts (no household) have no app shell to return
    // to, so surface sign-out instead of a back button.
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final showSignOut = profile != null && !profile.hasHousehold;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.adminTitle),
          automaticallyImplyLeading: !showSignOut,
          actions: [
            if (showSignOut)
              IconButton(
                onPressed: () => _confirmSignOut(context, ref),
                icon: const Icon(Icons.logout),
                tooltip: AppStrings.signOut,
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: AppStrings.adminSectionFeedback),
              Tab(text: AppStrings.adminSectionErrors),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _FeedbackTab(),
            _ErrorsTab(),
          ],
        ),
      ),
    );
  }
}

class _FeedbackTab extends ConsumerWidget {
  const _FeedbackTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackAsync = ref.watch(adminFeedbackProvider);
    return AsyncScreenBody(
      value: feedbackAsync,
      onRetry: () => ref.invalidate(adminFeedbackProvider),
      builder: (items) {
        if (items.isEmpty) {
          return const _EmptyState(message: AppStrings.adminNoFeedback);
        }
        return _GroupedManagedList<FeedbackEntry>(
          items: items,
          idOf: (e) => e.id,
          dateOf: (e) => e.createdAt,
          cardBuilder: (e) => _FeedbackCard(entry: e),
          onRefresh: () => ref.refresh(adminFeedbackProvider.future),
          onDelete: (ids) =>
              ref.read(adminRepositoryProvider).deleteFeedback(ids),
        );
      },
    );
  }
}

class _ErrorsTab extends ConsumerWidget {
  const _ErrorsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorsAsync = ref.watch(adminErrorReportsProvider);
    return AsyncScreenBody(
      value: errorsAsync,
      onRetry: () => ref.invalidate(adminErrorReportsProvider),
      builder: (items) {
        if (items.isEmpty) {
          return const _EmptyState(message: AppStrings.adminNoErrors);
        }
        return _GroupedManagedList<ErrorReportEntry>(
          items: items,
          idOf: (e) => e.id,
          dateOf: (e) => e.createdAt,
          cardBuilder: (e) => _ErrorCard(entry: e),
          onRefresh: () => ref.refresh(adminErrorReportsProvider.future),
          onDelete: (ids) =>
              ref.read(adminRepositoryProvider).deleteErrorReports(ids),
        );
      },
    );
  }
}

/// A pull-to-refresh list that groups entries by day and supports deleting a
/// single item (swipe), a whole day's group, or everything.
///
/// Keeps a local mutable copy so deletes feel instant without flashing a
/// full-screen loading state; it re-syncs from [items] whenever the parent
/// provider yields a new list (e.g. on refresh).
class _GroupedManagedList<T> extends StatefulWidget {
  const _GroupedManagedList({
    super.key,
    required this.items,
    required this.idOf,
    required this.dateOf,
    required this.cardBuilder,
    required this.onRefresh,
    required this.onDelete,
  });

  final List<T> items;
  final String Function(T) idOf;
  final DateTime? Function(T) dateOf;
  final Widget Function(T) cardBuilder;
  final Future<void> Function() onRefresh;
  final Future<void> Function(List<String> ids) onDelete;

  @override
  State<_GroupedManagedList<T>> createState() => _GroupedManagedListState<T>();
}

class _GroupedManagedListState<T> extends State<_GroupedManagedList<T>> {
  late List<T> _items = List<T>.of(widget.items);

  @override
  void didUpdateWidget(covariant _GroupedManagedList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.items, widget.items)) {
      _items = List<T>.of(widget.items);
    }
  }

  String _dayLabel(DateTime? date) {
    if (date == null) return AppStrings.adminUnknownReporter;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final local = date.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return AppStrings.adminGroupToday;
    if (diff == 1) return AppStrings.adminGroupYesterday;
    return Formatters.date(local);
  }

  List<MapEntry<String, List<T>>> get _groups {
    final map = <String, List<T>>{};
    for (final item in _items) {
      map.putIfAbsent(_dayLabel(widget.dateOf(item)), () => <T>[]).add(item);
    }
    return map.entries.toList();
  }

  Future<bool> _confirm(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.adminDeleteTitle),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _performDelete(List<String> ids) async {
    if (ids.isEmpty) return;
    final idSet = ids.toSet();
    setState(() => _items.removeWhere((e) => idSet.contains(widget.idOf(e))));
    try {
      await widget.onDelete(ids);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.adminDeleted)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.adminDeleteFailed)),
      );
      // Re-sync from the server so the optimistic removal is undone.
      await widget.onRefresh();
    }
  }

  Future<void> _confirmAndDelete(List<String> ids, String message) async {
    if (await _confirm(message)) {
      await _performDelete(ids);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = _groups;
    final allIds = _items.map(widget.idOf).toList();

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _confirmAndDelete(
                allIds,
                AppStrings.adminDeleteAllConfirm,
              ),
              icon: Icon(Icons.delete_sweep_outlined,
                  color: theme.colorScheme.error),
              label: Text(
                AppStrings.adminClearAll,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ),
          for (final group in groups) ...[
            _GroupHeader(
              label: group.key,
              count: group.value.length,
              onDeleteGroup: () => _confirmAndDelete(
                group.value.map(widget.idOf).toList(),
                AppStrings.adminDeleteGroupConfirm,
              ),
            ),
            for (final item in group.value)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Dismissible(
                  key: ValueKey(widget.idOf(item)),
                  direction: DismissDirection.endToStart,
                  background: const _DismissBackground(),
                  confirmDismiss: (_) =>
                      _confirm(AppStrings.adminDeleteItemConfirm),
                  onDismissed: (_) => _performDelete([widget.idOf(item)]),
                  child: widget.cardBuilder(item),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.label,
    required this.count,
    required this.onDeleteGroup,
  });

  final String label;
  final int count;
  final VoidCallback onDeleteGroup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Text(
            '($count)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onDeleteGroup,
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            tooltip: AppStrings.delete,
          ),
        ],
      ),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.delete,
            style: TextStyle(
              color: theme.colorScheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.delete_outline, color: theme.colorScheme.onErrorContainer),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.entry});

  final FeedbackEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = [
      entry.reporterName ?? AppStrings.adminUnknownReporter,
      if (entry.appVersion != null) entry.appVersion!,
      if (entry.createdAt != null) Formatters.date(entry.createdAt!),
    ].join(' · ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _TypeChip(type: entry.type),
                const Spacer(),
                if (entry.createdAt != null)
                  Text(
                    Formatters.date(entry.createdAt!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(entry.message, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 10),
            Text(
              meta,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (entry.contactEmail != null &&
                entry.contactEmail!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.mail_outline,
                      size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      entry.contactEmail!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.entry});

  final ErrorReportEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = [
      entry.reporterName ?? AppStrings.adminAnonymous,
      if (entry.platform != null) entry.platform!,
      if (entry.appVersion != null) entry.appVersion!,
      if (entry.createdAt != null) Formatters.date(entry.createdAt!),
    ].join(' · ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 12),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            leading: Icon(Icons.error_outline, color: theme.colorScheme.error),
            title: Text(
              entry.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            children: [
              if (entry.error != null && entry.error!.isNotEmpty)
                _CodeBlock(label: 'error', text: entry.error!),
              if (entry.stackTrace != null && entry.stackTrace!.isNotEmpty)
                _CodeBlock(label: 'stack', text: entry.stackTrace!),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = switch (type) {
      'bug' => (AppStrings.feedbackTypeBug, theme.colorScheme.error),
      'feature' => (AppStrings.feedbackTypeFeature, theme.colorScheme.primary),
      _ => (AppStrings.feedbackTypeOther, theme.colorScheme.tertiary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}
