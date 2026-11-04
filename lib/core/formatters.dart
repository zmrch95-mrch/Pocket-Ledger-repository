import 'package:intl/intl.dart';

String localizeDigits(String value, {String locale = 'en'}) {
  if (locale != 'ar') return value;

  return value.replaceAllMapped(RegExp(r'[0-9]'), (match) {
    final digit = match.group(0)!.codeUnitAt(0) - 0x30;
    return String.fromCharCode(0x0660 + digit);
  });
}

String normalizeDigits(String value) {
  return value.replaceAllMapped(RegExp(r'[\u0660-\u0669\u06F0-\u06F9]'), (
    match,
  ) {
    final digit = match.group(0)!.codeUnitAt(0);
    final westernDigit = digit >= 0x06F0 ? digit - 0x06F0 : digit - 0x0660;
    return String.fromCharCode(0x30 + westernDigit);
  });
}

String formatCurrency(
  int amountCents,
  String currencyCode, {
  String locale = 'en',
  String? currencyDisplayName,
}) {
  final amount = amountCents / 100;
  final formattedAmount = NumberFormat('#,##0.00', locale).format(amount);
  // Keep the ISO code visible by default; callers may provide a localized
  // display label.
  final currencyLabel = currencyDisplayName ?? currencyCode.toUpperCase();
  return '${localizeDigits(formattedAmount, locale: locale)} $currencyLabel';
}

String formatDate(DateTime date, {String locale = 'en'}) {
  final formatted = DateFormat('dd-MM-yyyy').format(date);
  return localizeDigits(formatted, locale: locale);
}

String toIsoDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

String formatTime(String time) {
  final normalized = normalizeDigits(time);
  final parsed = DateFormat('HH:mm').parseStrict(normalized);
  return DateFormat('HH:mm').format(parsed);
}

String formatTimeForDisplay(String time, {String locale = 'en'}) {
  final normalized = normalizeDigits(time);
  final parsed = DateFormat('HH:mm').parseStrict(normalized);
  if (locale == 'ar') {
    final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final marker = parsed.hour < 12 ? 'ص' : 'م';
    return localizeDigits('$hour:$minute $marker', locale: locale);
  }

  final formatted = DateFormat('h:mm a').format(parsed);
  return localizeDigits(formatted, locale: locale);
}

DateTime parseExpenseDate(String value) {
  final input = normalizeDigits(value).trim();

  try {
    return DateFormat('dd-MM-yyyy').parseStrict(input);
  } on FormatException {
    try {
      return DateFormat('yyyy-MM-dd').parseStrict(input);
    } on FormatException {
      throw FormatException('Use DD-MM-YYYY, for example 15-10-2026.', value);
    }
  }
}

int parseAmountToCents(String input) {
  final normalized = normalizeDigits(input)
      .trim()
      .replaceAll('\u066C', '')
      .replaceAll('\u066B', '.')
      .replaceAll(',', '.');
  final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(normalized);

  if (match == null) {
    throw const FormatException(
      'Enter a positive amount with up to two decimal places.',
    );
  }

  final whole = int.parse(match.group(1)!);
  final fraction = (match.group(2) ?? '').padRight(2, '0');
  final cents = whole * 100 + (fraction.isEmpty ? 0 : int.parse(fraction));

  if (cents <= 0) {
    throw const FormatException('The amount must be greater than zero.');
  }

  return cents;
}

String formatCentsForInput(int amountCents, {String locale = 'en'}) {
  final whole = amountCents ~/ 100;
  final fraction = (amountCents % 100).toString().padLeft(2, '0');
  return localizeDigits('$whole.$fraction', locale: locale);
}

String formatMonthLabel(DateTime date, String languageCode) {
  const english = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  const arabic = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
  final months = languageCode == 'ar' ? arabic : english;
  return '${months[date.month - 1]} ${localizeDigits('${date.year}', locale: languageCode)}';
}
