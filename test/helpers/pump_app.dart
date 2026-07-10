import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/core/theme/app_theme.dart';
import 'package:myplanr/shared/widgets/app_text_field.dart';
import 'package:myplanr/shared/widgets/loading_button.dart';

Future<void> pumpTestApp(
  WidgetTester tester, {
  required Widget child,
  List<Override> overrides = const [],
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: theme ?? AppTheme.light,
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Wraps [child] under a minimal [GoRouter] for screens that use shell navigation.
Future<void> pumpShellTestApp(
  WidgetTester tester, {
  required Widget child,
  List<Override> overrides = const [],
  String initialLocation = '/',
}) async {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => child,
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapSave(WidgetTester tester, {int? index}) async {
  if (index != null) {
    await tapLabeledButtonAt(tester, AppStrings.save, index);
    return;
  }
  await tapLabeledButton(tester, AppStrings.save);
}

Future<void> tapLabeledButtonAt(
  WidgetTester tester,
  String label,
  int index,
) async {
  final buttons = find.byType(LoadingButton);
  var matchIndex = 0;
  for (var i = 0; i < buttons.evaluate().length; i++) {
    final buttonFinder = buttons.at(i);
    final button = tester.widget<LoadingButton>(buttonFinder);
    if (button.label == label) {
      if (matchIndex == index) {
        await tester.ensureVisible(buttonFinder);
        await tester.tap(buttonFinder);
        await tester.pumpAndSettle();
        return;
      }
      matchIndex++;
    }
  }
  fail('No LoadingButton at index $index for label $label');
}

Future<void> tapLabeledButton(WidgetTester tester, String label) async {
  final buttons = find.byType(LoadingButton);
  for (var i = buttons.evaluate().length - 1; i >= 0; i--) {
    final buttonFinder = buttons.at(i);
    final button = tester.widget<LoadingButton>(buttonFinder);
    if (button.label != label) continue;
    try {
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();
      return;
    } catch (_) {
      continue;
    }
  }

  fail('No tappable LoadingButton found for label $label');
}

/// Opens [screen] via [Navigator.push] so screens that call [Navigator.pop] can be tested.
Future<void> pumpPushedScreen(
  WidgetTester tester, {
  required Widget screen,
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: const Key('open_pushed_screen'),
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(builder: (_) => screen),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('open_pushed_screen')));
  await tester.pumpAndSettle();
}

Future<void> enterTextByLabel(
  WidgetTester tester,
  String label,
  String value,
) async {
  final appFields = find.byType(AppTextField, skipOffstage: false);
  for (var i = appFields.evaluate().length - 1; i >= 0; i--) {
    final appFieldFinder = appFields.at(i);
    final appField = tester.widget<AppTextField>(appFieldFinder);
    if (appField.label == label) {
      final field = find.descendant(
        of: appFieldFinder,
        matching: find.byType(TextFormField),
      );
      try {
        await tester.ensureVisible(field);
        await tester.enterText(field, value);
        await tester.pumpAndSettle();
        return;
      } catch (_) {
        continue;
      }
    }
  }

  final semantic = find.bySemanticsLabel(label, skipOffstage: false);
  if (semantic.evaluate().isNotEmpty) {
    await tester.ensureVisible(semantic);
    await tester.enterText(semantic, value);
    await tester.pumpAndSettle();
    return;
  }

  final fields = find.byType(TextFormField, skipOffstage: false);
  Finder? target;
  for (var i = 0; i < fields.evaluate().length; i++) {
    final fieldFinder = fields.at(i);
    final decoratorFinder = find.ancestor(
      of: fieldFinder,
      matching: find.byType(InputDecorator),
    );
    if (decoratorFinder.evaluate().isEmpty) continue;
    final decorator = tester.widget<InputDecorator>(decoratorFinder);
    if (decorator.decoration.labelText == label) {
      target = fieldFinder;
      break;
    }
  }
  expect(target, isNotNull, reason: 'No field for label $label');
  await tester.ensureVisible(target!);
  await tester.enterText(target, value);
  await tester.pumpAndSettle();
}
