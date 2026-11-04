import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ledger/core/validators.dart';

void main() {
  group('validateTextLabel', () {
    test('accepts labels containing English letters', () {
      expect(
        validateTextLabel('Weekly groceries', label: 'expense name'),
        isNull,
      );
    });

    test('accepts labels containing Arabic letters', () {
      expect(
        validateTextLabel('مشتريات المنزل', label: 'category name'),
        isNull,
      );
    });

    test('rejects numeric-only labels', () {
      expect(
        validateTextLabel('12345', label: 'expense name'),
        contains('at least one letter'),
      );
    });

    test('rejects empty and excessively long labels', () {
      expect(validateTextLabel('   ', label: 'category name'), isNotNull);
      expect(
        validateTextLabel(
          List.filled(51, 'a').join(),
          label: 'category name',
          maxLength: 50,
        ),
        contains('50 characters or fewer'),
      );
    });
  });
}
