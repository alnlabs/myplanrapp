import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/pantry_availability.dart';
import '../../../shared/constants/pantry_constants.dart';
import '../../../shared/models/expense.dart';
import '../../../shared/models/pantry_item.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/utils/offline_guard.dart';
import '../../auth/data/auth_repository.dart';
import '../../expenses/data/expense_repository.dart';
import '../../pantry/data/pantry_repository.dart';
import '../../shopping/data/shopping_repository.dart';
import '../data/assistant_repository.dart';
import '../data/models/receipt_analysis.dart';

class ReceiptPreviewScreen extends ConsumerStatefulWidget {
  const ReceiptPreviewScreen({
    super.key,
    required this.analysis,
    this.imageBytes,
    this.mimeType,
  });

  final ReceiptAnalysis analysis;
  final Uint8List? imageBytes;
  final String? mimeType;

  @override
  ConsumerState<ReceiptPreviewScreen> createState() =>
      _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends ConsumerState<ReceiptPreviewScreen> {
  late List<ReceiptLine> _lines;
  final Set<int> _appliedIndexes = {}; // by line.lineIndex
  bool _expenseApplied = false;

  late final TextEditingController _merchant;
  late final TextEditingController _amount;
  late DateTime _date;
  String? _categoryId;

  String? _receiptId;
  String? _householdId;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _lines = List.of(widget.analysis.lines);
    _merchant = TextEditingController(text: widget.analysis.merchant ?? '');
    _amount = TextEditingController(
      text: widget.analysis.total != null
          ? widget.analysis.total!.toStringAsFixed(2)
          : '',
    );
    _date = widget.analysis.purchasedAt ?? DateTime.now();
    _categoryId = widget.analysis.suggestedCategoryId;
  }

  @override
  void dispose() {
    _merchant.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<String> _ensureHousehold() async {
    if (_householdId != null) return _householdId!;
    final profile = await ref.read(userProfileProvider.future);
    final id = profile?.activeHouseholdId;
    if (id == null) throw Exception(AppStrings.noHousehold);
    _householdId = id;
    return id;
  }

  Future<String> _ensureReceipt() async {
    if (_receiptId != null) return _receiptId!;
    final householdId = await _ensureHousehold();
    final id = await ref.read(assistantRepositoryProvider).persistReceipt(
          householdId: householdId,
          analysis: widget.analysis,
          lines: _lines,
          imageBytes: widget.imageBytes,
          mimeType: widget.mimeType,
        );
    _receiptId = id;
    return id;
  }

  Future<void> _guard(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      ref.ensureOnline();
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = ApiErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _doApplyExpense() async {
    final householdId = await _ensureHousehold();
    await _ensureReceipt();
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    if (amount <= 0 || _categoryId == null) {
      throw Exception(AppStrings.receiptApplyFailed);
    }
    final title = _merchant.text.trim().isEmpty
        ? AppStrings.receiptExpenseSection
        : _merchant.text.trim();
    await ref.read(expenseRepositoryProvider).createExpense(
          householdId: householdId,
          categoryId: _categoryId!,
          amount: amount,
          title: title,
          expenseDate: _date,
        );
    _expenseApplied = true;
  }

  Future<void> _doApplyLine(ReceiptLine line) async {
    final householdId = await _ensureHousehold();
    final receiptId = await _ensureReceipt();

    switch (line.destination) {
      case ReceiptLineDestination.pantry:
        if (line.matchedItemId != null) {
          await ref.read(pantryRepositoryProvider).applyStockEvent(
                itemId: line.matchedItemId!,
                delta: line.qty ?? 1,
                reason: 'restocked',
                note: AppStrings.receiptApplyDone,
              );
        } else {
          await ref.read(pantryRepositoryProvider).createItem(
                PantryItem(
                  id: '',
                  householdId: householdId,
                  name: line.name,
                  quantity: line.qty ?? 1,
                  unit: line.unit ?? 'pcs',
                  availabilityStatus: PantryAvailability.fine,
                ),
                householdId,
              );
        }
        break;
      case ReceiptLineDestination.shopping:
        await ref.read(shoppingRepositoryProvider).addItem(
              householdId: householdId,
              name: line.name,
              quantity: line.qty,
              unit: line.unit,
            );
        break;
      case ReceiptLineDestination.ignore:
        return;
    }

    await ref.read(assistantRepositoryProvider).markLineApplied(
          receiptId: receiptId,
          lineIndex: line.lineIndex,
        );
    _appliedIndexes.add(line.lineIndex);
  }

  bool get _allDone {
    if (!_expenseApplied) return false;
    return _lines
        .where((l) => l.destination != ReceiptLineDestination.ignore)
        .every((l) => _appliedIndexes.contains(l.lineIndex));
  }

  Future<void> _maybeMarkProcessed() async {
    if (_allDone && _receiptId != null) {
      await ref.read(assistantRepositoryProvider).markReceiptProcessed(_receiptId!);
    }
  }

  Future<void> _applyExpense() => _guard(() async {
        await _doApplyExpense();
        await _maybeMarkProcessed();
      });

  Future<void> _applyLine(ReceiptLine line) => _guard(() async {
        await _doApplyLine(line);
        await _maybeMarkProcessed();
      });

  Future<void> _applyAll() => _guard(() async {
        if (!_expenseApplied && (double.tryParse(_amount.text.trim()) ?? 0) > 0) {
          await _doApplyExpense();
        }
        for (final line in _lines) {
          if (line.destination == ReceiptLineDestination.ignore) continue;
          if (_appliedIndexes.contains(line.lineIndex)) continue;
          await _doApplyLine(line);
        }
        await _maybeMarkProcessed();
        // Stay on the screen so the user can see each item flip to "Applied".
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.receiptApplyDone)),
          );
        }
      });

  Future<void> _editLine(ReceiptLine line) async {
    final updated = await showModalBottomSheet<ReceiptLine>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditLineSheet(line: line),
    );
    if (updated == null) return;
    setState(() {
      final idx = _lines.indexWhere((l) => l.lineIndex == line.lineIndex);
      if (idx != -1) _lines[idx] = updated;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(expenseCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.receiptPreviewTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 12),
            ],
            _sectionHeader(AppStrings.receiptExpenseSection),
            const SizedBox(height: 8),
            _buildExpenseCard(categoriesAsync),
            const SizedBox(height: 24),
            _sectionHeader(AppStrings.receiptItemsSection),
            const SizedBox(height: 8),
            if (_lines.isEmpty)
              Text(
                AppStrings.receiptNoItems,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              for (final line in _lines) ...[
                _buildLineTile(line),
                const SizedBox(height: 8),
              ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: _allDone
              ? FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check),
                  label: const Text(AppStrings.doneLabel),
                )
              : FilledButton.icon(
                  onPressed: _busy ? null : _applyAll,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.done_all),
                  label: const Text(AppStrings.receiptApplyAll),
                ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _buildExpenseCard(AsyncValue<List<ExpenseCategory>> categoriesAsync) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _merchant,
              decoration: const InputDecoration(
                labelText: AppStrings.receiptMerchant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                labelText: AppStrings.receiptAmount,
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 12),
            categoriesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text(AppStrings.errorGeneric),
              data: (categories) {
                if (_categoryId == null && categories.isNotEmpty) {
                  _categoryId = categories.first.id;
                }
                final hasCategory =
                    categories.any((c) => c.id == _categoryId);
                return DropdownButtonFormField<String>(
                  value: hasCategory ? _categoryId : null,
                  decoration:
                      const InputDecoration(labelText: AppStrings.category),
                  items: categories
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                );
              },
            ),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.receiptDate),
              subtitle: Text(Formatters.date(_date)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: _expenseApplied
                  ? Chip(
                      avatar: Icon(Icons.check_circle,
                          size: 18, color: theme.colorScheme.primary),
                      label: const Text(AppStrings.receiptExpenseAdded),
                    )
                  : OutlinedButton.icon(
                      onPressed: _busy ? null : _applyExpense,
                      icon: const Icon(Icons.add),
                      label: const Text(AppStrings.receiptExpenseCreate),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineTile(ReceiptLine line) {
    final theme = Theme.of(context);
    final applied = _appliedIndexes.contains(line.lineIndex);
    final qtyLabel = line.qty != null
        ? '${_trimNum(line.qty!)} ${line.unit ?? ''}'.trim()
        : (line.unit ?? '');

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.name,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (qtyLabel.isNotEmpty)
                        Text(
                          qtyLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                _statusBadge(line, applied),
                IconButton(
                  onPressed: applied || _busy ? null : () => _editLine(line),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (!applied && line.destination != ReceiptLineDestination.ignore)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy ? null : () => _applyLine(line),
                  child: Text(_lineActionLabel(line)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(ReceiptLine line, bool applied) {
    final theme = Theme.of(context);
    late final String label;
    late final Color color;
    if (applied) {
      label = AppStrings.receiptApplied;
      color = theme.colorScheme.primary;
    } else {
      switch (line.destination) {
        case ReceiptLineDestination.ignore:
          label = AppStrings.receiptDestIgnore;
          color = theme.colorScheme.onSurfaceVariant;
          break;
        case ReceiptLineDestination.shopping:
          label = AppStrings.receiptDestShopping;
          color = Colors.orange.shade800;
          break;
        case ReceiptLineDestination.pantry:
          if (line.matchedItemId != null) {
            label = AppStrings.receiptStatusRestock;
            color = Colors.blue.shade700;
          } else {
            label = AppStrings.receiptStatusNew;
            color = Colors.green.shade700;
          }
          break;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

  String _lineActionLabel(ReceiptLine line) {
    return switch (line.destination) {
      ReceiptLineDestination.shopping => AppStrings.receiptActionAddShop,
      ReceiptLineDestination.pantry => line.matchedItemId != null
          ? AppStrings.receiptActionRestock
          : AppStrings.receiptActionCreate,
      ReceiptLineDestination.ignore => '',
    };
  }

  static String _trimNum(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }
}

class _EditLineSheet extends StatefulWidget {
  const _EditLineSheet({required this.line});

  final ReceiptLine line;

  @override
  State<_EditLineSheet> createState() => _EditLineSheetState();
}

class _EditLineSheetState extends State<_EditLineSheet> {
  late final TextEditingController _name;
  late final TextEditingController _qty;
  late String _unit;
  late ReceiptLineDestination _destination;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.line.name);
    _qty = TextEditingController(
      text: widget.line.qty != null
          ? _ReceiptPreviewScreenState._trimNum(widget.line.qty!)
          : '',
    );
    _unit = PantryUnits.values.contains(widget.line.unit)
        ? widget.line.unit!
        : 'pcs';
    _destination = widget.line.destination;
  }

  @override
  void dispose() {
    _name.dispose();
    _qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: AppStrings.itemName),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qty,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration:
                      const InputDecoration(labelText: AppStrings.quantity),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _unit,
                  decoration:
                      const InputDecoration(labelText: AppStrings.unit),
                  items: PantryUnits.values
                      .map((u) => DropdownMenuItem(
                            value: u,
                            child: Text(PantryUnits.label(u)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _unit = v ?? _unit),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ReceiptLineDestination>(
            value: _destination,
            decoration:
                const InputDecoration(labelText: AppStrings.receiptItemsSection),
            items: const [
              DropdownMenuItem(
                value: ReceiptLineDestination.pantry,
                child: Text(AppStrings.receiptDestPantry),
              ),
              DropdownMenuItem(
                value: ReceiptLineDestination.shopping,
                child: Text(AppStrings.receiptDestShopping),
              ),
              DropdownMenuItem(
                value: ReceiptLineDestination.ignore,
                child: Text(AppStrings.receiptDestIgnore),
              ),
            ],
            onChanged: (v) =>
                setState(() => _destination = v ?? _destination),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              final qty = double.tryParse(_qty.text.trim());
              Navigator.pop(
                context,
                widget.line.copyWith(
                  name: _name.text.trim().isEmpty
                      ? widget.line.name
                      : _name.text.trim(),
                  qty: qty,
                  unit: _unit,
                  destination: _destination,
                  clearMatch:
                      _destination != ReceiptLineDestination.pantry,
                ),
              );
            },
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
  }
}
