import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/offline_guard.dart';
import '../data/assistant_repository.dart';
import 'paste_receipt_screen.dart';
import 'receipt_preview_screen.dart';
import 'receipts_list_screen.dart';

class ScanReceiptScreen extends ConsumerStatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  ConsumerState<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends ConsumerState<ScanReceiptScreen> {
  final _picker = ImagePicker();
  bool _busy = false;
  String? _error;

  Future<void> _pick(ImageSource source) async {
    setState(() => _error = null);
    final XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        imageQuality: 60,
        maxWidth: 1280,
      );
    } catch (e) {
      setState(() => _error = ApiErrorFormatter.format(e));
      return;
    }
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final mimeType = _mimeForName(picked.name);
    await _analyze(bytes: bytes, mimeType: mimeType);
  }

  Future<void> _analyze({
    required Uint8List bytes,
    required String mimeType,
    bool force = false,
  }) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      ref.ensureOnline();
      final analysis = await ref.read(assistantRepositoryProvider).analyzeReceipt(
            bytes: bytes,
            mimeType: mimeType,
            force: force,
          );

      if (!mounted) return;

      if (analysis.alreadyProcessed && !force) {
        final proceed = await _confirmDuplicate();
        if (proceed == true) {
          await _analyze(bytes: bytes, mimeType: mimeType, force: true);
        }
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReceiptPreviewScreen(
            analysis: analysis,
            imageBytes: bytes,
            mimeType: mimeType,
          ),
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

  String _mimeForName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.assistantTitle),
        actions: [
          IconButton(
            tooltip: AppStrings.receiptsTitle,
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ReceiptsListScreen(),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _busy
            ? const _AnalyzingView()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 72,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.scanReceiptInstruction,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: () => _pick(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text(AppStrings.scanReceiptTakePhoto),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _pick(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text(AppStrings.scanReceiptFromGallery),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PasteReceiptScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.content_paste_outlined),
                      label: const Text(AppStrings.receiptPasteTile),
                    ),
                    Text(
                      AppStrings.receiptPasteHint,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _AnalyzingView extends StatelessWidget {
  const _AnalyzingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text(AppStrings.scanReceiptAnalyzing),
        ],
      ),
    );
  }
}
