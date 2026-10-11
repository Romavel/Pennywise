import 'package:flutter_test/flutter_test.dart';
import 'package:pennywise/core/utils/money.dart';

void main() {
  group('parseMinor', () {
    test('accepts dot, comma, whole numbers and spaces', () {
      expect(Money.parseMinor('45.99'), 4599);
      expect(Money.parseMinor('45,99'), 4599);
      expect(Money.parseMinor('45,9'), 4590);
      expect(Money.parseMinor('45'), 4500);
      expect(Money.parseMinor('45.'), 4500);
      expect(Money.parseMinor('1 234,50'), 123450);
      expect(Money.parseMinor('0.01'), 1);
      expect(Money.parseMinor('0'), 0);
    });

    test('rejects malformed input', () {
      for (final input in [
        '',
        'abc',
        '45.999',
        '1,234.50',
        '-5',
        '.5',
        '4 5x',
      ]) {
        expect(Money.parseMinor(input), isNull, reason: input);
      }
    });

    test('rejects amounts above the limit', () {
      expect(Money.parseMinor('1000000000'), Money.maxMinor);
      expect(Money.parseMinor('1000000000.01'), isNull);
      expect(Money.parseMinor('99999999999'), isNull);
    });

    test('works on integers, not floating point', () {
      expect(Money.parseMinor('0.29'), 29);
      expect(Money.parseMinor('1.15'), 115);
    });
  });

  group('formatting', () {
    test('format uses grouping and two decimals', () {
      expect(Money.format(458299), '4,582.99');
      expect(Money.format(5), '0.05');
      expect(Money.format(820000), '8,200.00');
    });

    test('formatSigned uses plus and a real minus sign', () {
      expect(Money.formatSigned(8640, positive: false), '−86.40');
      expect(Money.formatSigned(100000, positive: true), '+1,000.00');
    });

    test('toInput round-trips through parseMinor', () {
      for (final minor in [1, 50, 4599, 123456]) {
        expect(Money.parseMinor(Money.toInput(minor)), minor);
      }
      expect(Money.toInput(4605), '46.05');
    });
  });
}
