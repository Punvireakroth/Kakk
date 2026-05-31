import 'package:flutter_test/flutter_test.dart';

import 'package:kakk/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formats zero USD with two decimals', () {
      expect(CurrencyFormatter.format(0, currency: 'USD'), '\$0.00');
    });

    test('formats negative amounts', () {
      final formatted = CurrencyFormatter.format(-12.5, currency: 'USD');
      expect(formatted, contains('-'));
      expect(formatted, contains('12.50'));
    });

    test('KHR uses zero decimal digits', () {
      expect(CurrencyFormatter.getDecimalDigits('KHR'), 0);
      final formatted = CurrencyFormatter.format(1500, currency: 'KHR');
      expect(formatted, contains('1,500'));
      expect(formatted, isNot(contains('.00')));
    });

    test('parse strips symbols and commas', () {
      expect(CurrencyFormatter.parse('\$1,234.56'), 1234.56);
      expect(CurrencyFormatter.parse('invalid'), isNull);
    });

    test('getCurrencySymbol returns known symbol or code fallback', () {
      expect(CurrencyFormatter.getCurrencySymbol('EUR'), '€');
      expect(CurrencyFormatter.getCurrencySymbol('XYZ'), 'XYZ');
    });
  });
}
