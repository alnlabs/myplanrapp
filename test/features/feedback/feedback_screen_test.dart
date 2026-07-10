import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/feedback/data/feedback_repository.dart';
import 'package:myplanr/features/feedback/presentation/feedback_screen.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/stub_repositories.dart';

void main() {
  group('FeedbackScreen widget', () {
    testWidgets('renders feedback form', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          feedbackRepositoryProvider.overrideWith((ref) => StubFeedbackRepository()),
        ],
        child: const FeedbackScreen(),
      );

      expect(find.text(AppStrings.feedbackTitle), findsOneWidget);
      expect(find.text(AppStrings.feedbackHint), findsOneWidget);
      expect(find.text(AppStrings.feedbackSubmit), findsOneWidget);
    });

    testWidgets('requires message before submit', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          feedbackRepositoryProvider.overrideWith((ref) => StubFeedbackRepository()),
        ],
        child: const FeedbackScreen(),
      );

      await tapLabeledButton(tester, AppStrings.feedbackSubmit);
      expect(find.text(AppStrings.requiredField), findsOneWidget);
    });
  });
}
