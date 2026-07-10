import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/constants/subscription_constants.dart';

void main() {
  group('BillingCycles.labelFor', () {
    test('returns labels for known cycles', () {
      expect(BillingCycles.labelFor(BillingCycles.monthly), 'Monthly');
      expect(BillingCycles.labelFor(BillingCycles.yearly), 'Yearly');
    });

    test('returns raw value for unknown', () {
      expect(BillingCycles.labelFor('weekly'), 'weekly');
    });
  });

  group('PaymentMethods', () {
    test('labelFor returns payment labels', () {
      expect(PaymentMethods.labelFor(PaymentMethods.upi), 'UPI');
      expect(PaymentMethods.labelFor(PaymentMethods.cash), 'Cash');
    });

    test('detailHintFor returns contextual hints', () {
      expect(PaymentMethods.detailHintFor(PaymentMethods.upi), contains('@'));
      expect(PaymentMethods.detailHintFor(null), isNotEmpty);
    });
  });
}
