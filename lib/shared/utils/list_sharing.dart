import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_bottom_sheet.dart';
import '../../core/strings/app_strings.dart';

String formatShopListForSharing({
  required String title,
  required List<String> itemNames,
}) {
  if (itemNames.isEmpty) return title;
  final buffer = StringBuffer('$title\n');
  for (final name in itemNames) {
    buffer.writeln('• $name');
  }
  return buffer.toString().trimRight();
}

Future<void> copyTextToClipboard(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.shopListCopied)),
    );
  }
}

Future<void> shareViaWhatsApp(BuildContext context, String text) async {
  final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.shopListShareFailed)),
    );
  }
}

Future<void> showShareShopListSheet(
  BuildContext context, {
  required String text,
}) {
  return showAppBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.shareShopList,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                shareViaWhatsApp(context, text);
              },
              icon: const Icon(Icons.chat_outlined),
              label: const Text(AppStrings.shareViaWhatsApp),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                copyTextToClipboard(context, text);
              },
              icon: const Icon(Icons.copy_outlined),
              label: const Text(AppStrings.copyToClipboard),
            ),
          ],
        ),
      ),
    ),
  );
}
