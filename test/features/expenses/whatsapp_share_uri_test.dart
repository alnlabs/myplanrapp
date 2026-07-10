import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/features/expenses/utils/whatsapp_share_uri.dart';

void main() {
  group('buildWhatsAppShareUri', () {
    test('encodes text for wa.me link', () {
      final uri = buildWhatsAppShareUri('Hello, world!');
      expect(uri.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.query, 'text=Hello%2C%20world!');
    });
  });
}
