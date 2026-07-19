import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../auth/data/auth_repository.dart';
import '../data/assistant_repository.dart';
import 'receipt_preview_screen.dart';

/// Bring-your-own-AI entry point. The user copies our prompt, runs it in any AI
/// app, and pastes the JSON reply here. Everything is parsed locally, so there
/// is no server model call and no scan-limit cost.
class PasteReceiptScreen extends ConsumerStatefulWidget {
  const PasteReceiptScreen({super.key});

  @override
  ConsumerState<PasteReceiptScreen> createState() => _PasteReceiptScreenState();
}

class _PasteReceiptScreenState extends ConsumerState<PasteReceiptScreen> {
  final _input = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _copyPrompt() async {
    await Clipboard.setData(const ClipboardData(text: AppStrings.receiptPastePrompt));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.receiptPastePromptCopied)),
    );
  }

  Future<void> _review() async {
    final text = _input.text.trim();
    if (text.isEmpty) {
      setState(() => _error = AppStrings.receiptPasteEmpty);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final profile = await ref.read(userProfileProvider.future);
      final householdId = profile?.activeHouseholdId;
      if (householdId == null) {
        throw Exception(AppStrings.receiptPasteNoHousehold);
      }
      final analysis = await ref.read(assistantRepositoryProvider).analyzePasted(
            jsonText: text,
            householdId: householdId,
          );
      if (!mounted) return;

      if (analysis.alreadyProcessed) {
        final proceed = await _confirmDuplicate();
        if (proceed != true) return;
      }
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReceiptPreviewScreen(analysis: analysis),
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = ApiErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _confirmDuplicate() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.receiptDuplicateTitle),
        content: const Text(AppStrings.receiptDuplicateBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.receiptProcessAnyway),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.receiptPasteTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _step(theme, AppStrings.receiptPasteStep1),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                AppStrings.receiptPastePrompt,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _copyPrompt,
                icon: const Icon(Icons.copy_outlined, size: 18),
                label: const Text(AppStrings.receiptPasteCopyPrompt),
              ),
            ),
            const SizedBox(height: 20),
            _step(theme, AppStrings.receiptPasteStep2),
            const SizedBox(height: 20),
            _step(theme, AppStrings.receiptPasteStep3),
            const SizedBox(height: 8),
            TextField(
              controller: _input,
              minLines: 5,
              maxLines: 12,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                labelText: AppStrings.receiptPasteInputLabel,
                hintText: AppStrings.receiptPasteInputHint,
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _busy ? null : _review,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.done_all),
              label: const Text(AppStrings.receiptPasteReview),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
