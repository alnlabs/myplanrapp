import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/features/app_updates/services/app_review_service.dart';
import 'package:myplanr/features/app_updates/services/app_update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppUpdateService', () {
    test('manual check returns notSupported off Android', () async {
      if (Platform.isAndroid) return;

      final result = await AppUpdateService.instance.checkManually();
      expect(result, AppUpdateCheckResult.notSupported);
    });
  });

  group('AppReviewService', () {
    test('increments launch count without requesting review early', () async {
      SharedPreferences.setMockInitialValues({});

      await AppReviewService.instance.registerLaunchAndMaybeAsk();
      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getInt('app_launch_count'), 1);
      expect(prefs.getBool('review_requested'), isNull);
    });

    test('does not increment after review already requested', () async {
      SharedPreferences.setMockInitialValues({
        'review_requested': true,
        'app_launch_count': 10,
      });

      await AppReviewService.instance.registerLaunchAndMaybeAsk();
      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getInt('app_launch_count'), 10);
    });
  });
}
