import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/providers/record_permissions.dart';
import '../../alerts/services/notification_service.dart';
import '../../assets/data/asset_repository.dart';
import '../../assistant/data/assistant_repository.dart';
import '../../auth/data/auth_repository.dart';
import '../../expenses/data/expense_groups_repository.dart';
import '../../expenses/data/expenses_list_provider.dart';
import '../../pantry/data/pantry_items_list_provider.dart';
import '../../pantry/data/pantry_repository.dart';
import '../../plans/data/plans_list_provider.dart';
import '../../reminders/data/reminder_repository.dart';
import '../../shopping/data/shopping_list_provider.dart';
import '../../subscriptions/data/subscription_repository.dart';
import '../data/data_reset_repository.dart';

class ResetDataScreen extends ConsumerStatefulWidget {
  const ResetDataScreen({super.key});

  @override
  ConsumerState<ResetDataScreen> createState() => _ResetDataScreenState();
}

class _ResetDataScreenState extends ConsumerState<ResetDataScreen> {
  final Set<String> _selected = <String>{};
  bool _busy = false;

  Future<void> _reset() async {
    if (_selected.isEmpty) {
      _snack(AppStrings.resetNothingSelected);
      return;
    }
    final confirmed = await _confirmReset(_selected.length);
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      final profile = await ref.read(userProfileProvider.future);
      final householdId = profile?.activeHouseholdId;
      if (householdId == null) {
        throw StateError('No active household');
      }
      final features = _selected.toSet();
      final counts = await ref
          .read(dataResetRepositoryProvider)
          .resetData(householdId, features.toList());
      final total = counts.values.fold<int>(0, (sum, n) => sum + n);
      await _invalidateAfterReset(features);
      if (!mounted) return;
      setState(() {
        _selected.clear();
        _busy = false;
      });
      _snack(AppStrings.resetDone(total));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      // 57014 = statement_timeout: the reset exceeded the DB time budget.
      final tooLarge = e is PostgrestException && e.code == '57014';
      _snack(tooLarge ? AppStrings.resetTooLarge : AppStrings.resetFailed);
    }
  }

  Future<bool> _confirmReset(int count) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final canConfirm = controller.text.trim().toUpperCase() ==
              AppStrings.resetConfirmWord;
          return AlertDialog(
            title: const Text(AppStrings.resetConfirmTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.resetConfirmBody(count)),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: AppStrings.resetConfirmPrompt,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setLocal(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed:
                    canConfirm ? () => Navigator.pop(ctx, true) : null,
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Theme.of(ctx).colorScheme.onError,
                ),
                child: const Text(AppStrings.resetConfirmAction),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
    return confirmed ?? false;
  }

  Future<void> _invalidateAfterReset(Set<String> f) async {
    if (f.contains('money')) {
      await refreshExpensesData(ref);
      ref.invalidate(expenseGroupsProvider);
    }
    if (f.contains('pantry')) {
      await refreshPantryList(ref);
      ref.invalidate(lowStockItemsProvider);
      ref.invalidate(expiringItemsProvider);
    }
    if (f.contains('shopping')) ref.invalidate(shoppingListProvider);
    if (f.contains('assets')) {
      ref.invalidate(homeAssetsProvider);
      ref.invalidate(warrantyExpiringAssetsProvider);
    }
    if (f.contains('subscriptions')) {
      ref.invalidate(subscriptionsProvider);
      ref.invalidate(subscriptionsDueSoonProvider);
    }
    if (f.contains('reminders')) ref.invalidate(appRemindersProvider);
    if (f.contains('plans')) await refreshPlansData(ref);
    if (f.contains('receipts')) ref.invalidate(savedReceiptsProvider);

    // Scheduled local notifications point at rows we just deleted; clear them.
    if (f.contains('reminders') ||
        f.contains('plans') ||
        f.contains('subscriptions')) {
      await NotificationService.instance.cancelAll();
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwner = ref.watch(isHouseholdOwnerProvider);
    final allSelected = _selected.length == ResetFeature.all.length;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.resetDataTitle)),
      body: !isOwner
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  AppStrings.resetOwnerOnly,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          AppStrings.resetDataSubtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      CheckboxListTile(
                        title: Text(
                          AppStrings.resetSelectAll,
                          style: theme.textTheme.titleMedium,
                        ),
                        value: allSelected,
                        onChanged: _busy
                            ? null
                            : (v) => setState(() {
                                  if (v == true) {
                                    _selected
                                      ..clear()
                                      ..addAll(
                                          ResetFeature.all.map((e) => e.key));
                                  } else {
                                    _selected.clear();
                                  }
                                }),
                      ),
                      const Divider(height: 1),
                      for (final feature in ResetFeature.all)
                        CheckboxListTile(
                          title: Text(feature.label),
                          subtitle: Text(feature.description),
                          value: _selected.contains(feature.key),
                          onChanged: _busy
                              ? null
                              : (v) => setState(() {
                                    if (v == true) {
                                      _selected.add(feature.key);
                                    } else {
                                      _selected.remove(feature.key);
                                    }
                                  }),
                        ),
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed:
                            (_busy || _selected.isEmpty) ? null : _reset,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                        ),
                        icon: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Icon(Icons.delete_forever_outlined),
                        label: Text(_busy
                            ? AppStrings.resetInProgress
                            : AppStrings.resetButton),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
