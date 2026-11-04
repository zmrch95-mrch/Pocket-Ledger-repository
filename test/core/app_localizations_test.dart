import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ledger/core/app_localizations.dart';

void main() {
  test('English localization preserves the source text', () {
    const localization = AppLocalizations(Locale('en'));
    expect(localization.translate('Transactions'), 'Transactions');
  });

  test('Arabic localization translates primary navigation and settings', () {
    const localization = AppLocalizations(Locale('ar'));
    expect(localization.translate('Transactions'), 'المعاملات');
    expect(localization.translate('Settings'), 'الإعدادات');
    expect(localization.translate('Arabic'), 'العربية');
  });

  test('Arabic localizes built-in categories and preserves custom names', () {
    const localization = AppLocalizations(Locale('ar'));
    expect(localization.translateCategory('Food'), 'الطعام');
    expect(localization.translateCategory('food'), 'الطعام');
    expect(localization.translateCategory('Transport'), 'المواصلات');
    expect(
      localization.translateCategory('My custom category'),
      'My custom category',
    );
  });

  test('Arabic category names are compared by their visible labels', () {
    const localization = AppLocalizations(Locale('ar'));
    expect(localization.hasCategoryNameCollision('الطعام', ['Food']), isTrue);
    expect(
      localization.hasCategoryNameCollision('المواصلات', ['Transport']),
      isTrue,
    );
    expect(localization.hasCategoryNameCollision('خاصة', ['Food']), isFalse);
  });

  test(
    'Arabic localizes currency names while keeping ISO codes recognizable',
    () {
      const localization = AppLocalizations(Locale('ar'));
      expect(localization.translateCurrencyCode('EGP'), 'جنيه مصري (EGP)');
      expect(localization.translateCurrencyCode('USD'), 'دولار أمريكي (USD)');
      expect(localization.translateCurrencyName('EGP'), 'جنيه مصري');
      expect(localization.translateCurrencyName('USD'), 'دولار أمريكي');
      expect(localization.translateCurrencyName('EUR'), 'يورو');
      expect(localization.translateCurrencyName('GBP'), 'جنيه إسترليني');
      expect(localization.translateCurrencyName('SAR'), 'ريال سعودي');
      expect(localization.translateCurrencyName('AED'), 'درهم إماراتي');
    },
  );

  test('formatted Arabic strings replace named values', () {
    const localization = AppLocalizations(Locale('ar'));
    expect(
      localization.translateFormatted('"{name}" will be permanently deleted.', {
        'name': 'Food',
      }),
      'سيتم حذف «Food» نهائياً.',
    );
  });

  test('formatted Arabic strings localize numeric values', () {
    const localization = AppLocalizations(Locale('ar'));
    expect(
      localization.translateFormatted(
        'Choose another category for the {count} linked expenses.',
        {'count': 12},
      ),
      'اختر فئة أخرى لنقل المصروفات المرتبطة وعددها ١٢.',
    );
  });
}
