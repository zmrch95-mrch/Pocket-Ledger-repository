/// Shared validation for human-readable labels such as expense and category
/// names. Unicode letter matching means Arabic and other non-Latin scripts are
/// accepted as well as English.
final RegExp _unicodeLetter = RegExp(r'\p{L}', unicode: true);

String? validateTextLabel(
  String? value, {
  required String label,
  int maxLength = 80,
}) {
  final normalized = value?.trim() ?? '';

  if (normalized.isEmpty) {
    return label == 'expense name'
        ? 'Enter an expense name.'
        : 'Enter a $label.';
  }

  if (!_unicodeLetter.hasMatch(normalized)) {
    return 'The $label must contain at least one letter.';
  }

  if (normalized.length > maxLength) {
    return 'The $label must be $maxLength characters or fewer.';
  }

  return null;
}

void requireTextLabel(
  String value, {
  required String label,
  int maxLength = 80,
}) {
  final error = validateTextLabel(value, label: label, maxLength: maxLength);

  if (error != null) {
    throw FormatException(error);
  }
}
