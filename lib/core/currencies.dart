const supportedCurrencies = <String, String>{
  'EGP': 'Egyptian pound (EGP)',
  'USD': 'US dollar (USD)',
  'EUR': 'Euro (EUR)',
  'GBP': 'British pound (GBP)',
  'SAR': 'Saudi riyal (SAR)',
  'AED': 'UAE dirham (AED)',
};

String normalizeCurrencyCode(String value) {
  final code = value.trim().toUpperCase();
  if (!supportedCurrencies.containsKey(code)) {
    throw FormatException('Unsupported currency code: $value');
  }
  return code;
}
