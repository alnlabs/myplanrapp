import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// iPhone SE–class width used to surface horizontal overflow issues.
const compactPhoneSize = Size(320, 640);

/// Extra-narrow width for stress-testing labels and chips.
const narrowPhoneSize = Size(280, 640);

/// Very long strings for overflow regression tests.
const testVeryLongDisplayName =
    'Alexandersoningtonovich Bartholomew Worthingtonshire the Third of Extraordinarily Long Family Names';

const testVeryLongExpenseTitle =
    'Quarterly subscription renewal for cloud storage backup premium family plan with international roaming add-on package';

const testVeryLongNote =
    'Paid after negotiating a lengthy invoice correction involving multiple departments and follow-up emails spanning several weeks of back and forth.';

void setTestViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
}

void resetTestViewport(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

void useCompactPhoneViewport(WidgetTester tester) {
  setTestViewport(tester, compactPhoneSize);
  addTearDown(() => resetTestViewport(tester));
}

void useNarrowPhoneViewport(WidgetTester tester) {
  setTestViewport(tester, narrowPhoneSize);
  addTearDown(() => resetTestViewport(tester));
}

bool _isOverflowError(Object error) {
  final message = error.toString().toLowerCase();
  return message.contains('overflowed') ||
      message.contains('renderflex') ||
      message.contains('overflow');
}

/// Tracks layout overflow errors for the duration of [body].
Future<void> expectNoLayoutOverflow(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  final overflowErrors = <FlutterErrorDetails>[];
  final previousHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    if (_isOverflowError(details.exception)) {
      overflowErrors.add(details);
    }
    previousHandler?.call(details);
  };
  addTearDown(() => FlutterError.onError = previousHandler);

  await body();
  await tester.pumpAndSettle();

  final pumpException = tester.takeException();
  if (pumpException != null) {
    expect(
      _isOverflowError(pumpException),
      isFalse,
      reason: pumpException.toString(),
    );
  }

  expect(
    overflowErrors,
    isEmpty,
    reason: overflowErrors
        .map((e) => e.exceptionAsString())
        .join('\n'),
  );
}

Future<void> pumpAndSettleWithoutOverflow(WidgetTester tester) async {
  await tester.pumpAndSettle();
  final exception = tester.takeException();
  if (exception != null) {
    expect(
      _isOverflowError(exception),
      isFalse,
      reason: exception.toString(),
    );
  }
}
