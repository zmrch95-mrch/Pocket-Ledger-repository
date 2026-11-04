import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ledger/core/formatters.dart';

void main() {
  group('parseExpenseDate', () {
    test('accepts the user-facing day-first format', () {
      expect(parseExpenseDate('15-10-2026'), DateTime(2026, 10, 15));
    });

    test('accepts the old ISO format for CSV compatibility', () {
      expect(parseExpenseDate('2026-10-15'), DateTime(2026, 10, 15));
    });

    test('accepts Arabic and Persian digits', () {
      expect(parseExpenseDate('١٥-١٠-٢٠٢٦'), DateTime(2026, 10, 15));
      expect(parseExpenseDate('۱۵-۱۰-۲۰۲۶'), DateTime(2026, 10, 15));
    });

    test('rejects impossible dates', () {
      expect(
        () => parseExpenseDate('31-02-2026'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('parseAmountToCents', () {
    test('stores decimal amounts as integer cents', () {
      expect(parseAmountToCents('125.50'), 12550);
      expect(parseAmountToCents('12'), 1200);
      expect(parseAmountToCents('12,5'), 1250);
      expect(parseAmountToCents('١٢٫٥'), 1250);
      expect(parseAmountToCents('١٬٢٣٤٫٥٠'), 123450);
    });

    test('rejects zero, negative, and too many decimal places', () {
      expect(() => parseAmountToCents('0'), throwsA(isA<FormatException>()));
      expect(
        () => parseAmountToCents('-3.00'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => parseAmountToCents('1.234'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('formatCurrency', () {
    test('separates the amount from the currency code', () {
      expect(formatCurrency(123450, 'EGP'), '1,234.50 EGP');
    });

    test('uses Arabic digits for Arabic display', () {
      final formatted = formatCurrency(123450, 'EGP', locale: 'ar');
      expect(formatted, contains('١'));
      expect(formatted, isNot(contains('1')));
      expect(formatted, endsWith(' EGP'));
    });
    test('uses a localized currency display name when provided', () {
      final formatted = formatCurrency(
        123450,
        'EGP',
        locale: 'ar',
        currencyDisplayName: 'جنيه مصري',
      );
      expect(formatted, endsWith(' جنيه مصري'));
    });
  });

  group('formatDate and formatTime', () {
    test('uses Arabic digits for displayed dates', () {
      expect(formatDate(DateTime(2026, 10, 15), locale: 'ar'), '١٥-١٠-٢٠٢٦');
    });

    test('shows AM or PM with a localized twelve-hour time', () {
      expect(formatTimeForDisplay('03:05'), '3:05 AM');
      expect(formatTimeForDisplay('15:05'), '3:05 PM');
      expect(formatTimeForDisplay('03:05', locale: 'ar'), '٣:٠٥ ص');
      expect(formatTimeForDisplay('15:05', locale: 'ar'), '٣:٠٥ م');
      expect(formatTime('15:05'), '15:05');
    });
  });
}
