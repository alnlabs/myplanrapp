import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/legal_urls.dart';

Future<void> openTermsOfService(BuildContext context) =>
    _open(context, LegalUrls.termsOfService);

Future<void> openPrivacyPolicy(BuildContext context) =>
    _open(context, LegalUrls.privacyPolicy);

Future<void> openCompanyWebsite(BuildContext context) =>
    _open(context, LegalUrls.companyWebsite);

Future<void> _open(BuildContext context, Uri url) async {
  final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open link')),
    );
  }
}
