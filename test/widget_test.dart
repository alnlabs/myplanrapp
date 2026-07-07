import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:myplanr/shared/utils/validators.dart';

void main() {
  group('Validators', () {
    test('required rejects empty', () {
      expect(Validators.required(''), isNotNull);
      expect(Validators.required('  '), isNotNull);
      expect(Validators.required('dal'), isNull);
    });

    test('email validates format', () {
      expect(Validators.email('bad'), isNotNull);
      expect(Validators.email('user@example.com'), isNull);
    });

    test('positiveAmount rejects zero', () {
      expect(Validators.positiveAmount('0'), isNotNull);
      expect(Validators.positiveAmount('80'), isNull);
    });
  });

  testWidgets('ProviderScope smoke test', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SizedBox.shrink(),
      ),
    );
    expect(find.byType(SizedBox), findsOneWidget);
  });
}
