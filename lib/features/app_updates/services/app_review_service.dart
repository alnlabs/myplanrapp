import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles Play Store / App Store rating prompts.
///
/// The in-app review dialog is quota-limited by the OS, so we only ask once
/// after the user has opened the app a few times.
class AppReviewService {
  AppReviewService._();

  static final AppReviewService instance = AppReviewService._();

  final InAppReview _inAppReview = InAppReview.instance;

  static const _launchCountKey = 'app_launch_count';
  static const _reviewRequestedKey = 'review_requested';
  static const _launchThreshold = 4;

  /// Records an app open and, once the launch threshold is reached, asks the
  /// user for a rating exactly once.
  Future<void> registerLaunchAndMaybeAsk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_reviewRequestedKey) ?? false) return;

      final count = (prefs.getInt(_launchCountKey) ?? 0) + 1;
      await prefs.setInt(_launchCountKey, count);
      if (count < _launchThreshold) return;

      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        await prefs.setBool(_reviewRequestedKey, true);
      }
    } catch (_) {
      // Rating is best-effort; never surface errors to the user.
    }
  }

  /// Opens the store listing directly (used by the manual "Rate" action).
  Future<void> openStoreListing() async {
    try {
      await _inAppReview.openStoreListing();
    } catch (_) {}
  }
}
