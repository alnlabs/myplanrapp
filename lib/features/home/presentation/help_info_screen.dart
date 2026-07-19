import 'package:flutter/material.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/utils/legal_launcher.dart';
import '../../app_updates/services/app_review_service.dart';
import '../../feedback/presentation/feedback_screen.dart';

/// Consolidated "Help & info" page with feedback, rating, about and privacy.
class HelpInfoScreen extends StatelessWidget {
  const HelpInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.helpInfoTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text(AppStrings.feedbackTitle),
            subtitle: const Text(AppStrings.moreFeedbackHint),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const FeedbackScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text(AppStrings.rateApp),
            subtitle: const Text(AppStrings.rateAppHint),
            onTap: () => AppReviewService.instance.openStoreListing(),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text(AppStrings.drawerHelpAbout),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: AppStrings.appName,
              applicationVersion: AppStrings.appVersion,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text(AppStrings.privacyPolicy),
            onTap: () => openPrivacyPolicy(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              '${AppStrings.appName} ${AppStrings.appVersion}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
