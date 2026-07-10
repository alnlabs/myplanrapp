import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/utils/formatters.dart';

void main() {
  group('Formatters.currency', () {
    test('formats INR amount', () {
      expect(Formatters.currency(1000), contains('1,000'));
      expect(Formatters.currency(1000), contains('₹'));
    });
  });

  group('Formatters.date', () {
    test('formats date without time', () {
      final formatted = Formatters.date(DateTime(2026, 7, 8));
      expect(formatted, contains('8'));
      expect(formatted, contains('2026'));
    });
  });

  group('Formatters.quantity', () {
    test('uses integer text for whole numbers', () {
      expect(Formatters.quantity(2, 'kg'), '2 kg');
    });

    test('keeps decimals for fractional quantities', () {
      expect(Formatters.quantity(1.5, 'kg'), '1.5 kg');
    });
  });

  group('Formatters.pantryItemSubtitle', () {
    test('includes brand when present', () {
      expect(
        Formatters.pantryItemSubtitle(
          quantity: 2,
          unit: 'kg',
          brand: 'Tata',
        ),
        'Tata · 2 kg',
      );
    });

    test('omits brand when blank', () {
      expect(
        Formatters.pantryItemSubtitle(quantity: 3, unit: 'pcs', brand: '  '),
        '3 pcs',
      );
    });
  });
}
