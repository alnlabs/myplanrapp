import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/expenses/utils/income_form_validators.dart';

void main() {
  group('validateIncomeMemberId', () {
    test('rejects null and empty member id', () {
      expect(validateIncomeMemberId(null), AppStrings.incomeMemberRequired);
      expect(validateIncomeMemberId(''), AppStrings.incomeMemberRequired);
    });

    test('accepts non-empty member id', () {
      expect(validateIncomeMemberId('member-1'), isNull);
    });
  });
}
