import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/onboarding/presentation/onboarding_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('OnboardingScreen widget', () {
    testWidgets('renders first slide and navigation', (tester) async {
      await pumpShellTestApp(
        tester,
        child: const OnboardingScreen(),
      );

      expect(find.text(AppStrings.onboardingSlide1Title), findsOneWidget);
      expect(find.text(AppStrings.skip), findsOneWidget);
      expect(find.text(AppStrings.next), findsOneWidget);
    });
  });
}
