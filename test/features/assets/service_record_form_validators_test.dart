import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/assets/utils/service_record_form_validators.dart';
import 'package:myplanr/shared/constants/asset_constants.dart';

void main() {
  group('validateServiceRecordShopName', () {
    test('required for shop repair', () {
      expect(
        validateServiceRecordShopName(
          null,
          serviceType: ServiceTypes.shopRepair,
        ),
        AppStrings.requiredField,
      );
      expect(
        validateServiceRecordShopName(
          'AC Care',
          serviceType: ServiceTypes.shopRepair,
        ),
        isNull,
      );
    });

    test('optional for third-party service', () {
      expect(
        validateServiceRecordShopName(
          null,
          serviceType: ServiceTypes.thirdParty,
        ),
        isNull,
      );
    });
  });

  group('validateServiceRecordCost', () {
    test('allows empty cost', () {
      expect(validateServiceRecordCost(null), isNull);
      expect(validateServiceRecordCost(''), isNull);
    });

    test('rejects invalid amounts', () {
      expect(validateServiceRecordCost('0'), AppStrings.invalidAmount);
      expect(validateServiceRecordCost('abc'), AppStrings.invalidAmount);
    });

    test('accepts positive cost', () {
      expect(validateServiceRecordCost('499'), isNull);
    });
  });
}
