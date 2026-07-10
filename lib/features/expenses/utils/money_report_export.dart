import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/utils/app_bottom_sheet.dart';
import 'whatsapp_share_uri.dart';

Future<void> copyReportToClipboard(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.reportCopied)),
    );
  }
}

Future<void> shareReportViaWhatsApp(BuildContext context, String text) async {
  final uri = buildWhatsAppShareUri(text);
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.shopListShareFailed)),
    );
  }
}

Future<void> showMoneyReportExportSheet(
  BuildContext context, {
  required String csv,
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
              AppStrings.exportReport,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text(AppStrings.copyReport),
              onTap: () {
                Navigator.pop(context);
                copyReportToClipboard(context, csv);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: const Text(AppStrings.shareReport),
              onTap: () {
                Navigator.pop(context);
                shareReportViaWhatsApp(context, csv);
              },
            ),
          ],
        ),
      ),
    ),
  );
}
