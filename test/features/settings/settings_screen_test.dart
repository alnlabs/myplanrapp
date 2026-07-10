import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/auth/data/auth_repository.dart';
import 'package:myplanr/features/settings/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/provider_overrides.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/stub_repositories.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsScreen widget', () {
    testWidgets('renders settings sections', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          ...testAuthOverrides,
          authRepositoryProvider.overrideWith((ref) => StubAuthRepository()),
        ],
        child: const SettingsScreen(),
      );

      expect(find.text(AppStrings.settingsAppearanceSection), findsOneWidget);
      await tester.scrollUntilVisible(find.text(AppStrings.builtAndMaintainedBy), 100);
      expect(find.text(AppStrings.builtAndMaintainedBy), findsOneWidget);
      await tester.scrollUntilVisible(find.text(AppStrings.signOut), 100);
      expect(find.text(AppStrings.signOut), findsOneWidget);
    });
  });
}
