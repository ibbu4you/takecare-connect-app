/// Form validation, kept deliberately looser than the server's.
///
/// The server is the authority: every one of these fields is validated again
/// in a Laravel FormRequest, and the app surfaces those 422 messages field by
/// field. What happens here is only to save a round trip on the obvious
/// mistakes — an empty name, a typo'd email — so the rules stay permissive.
/// A validator stricter than the server's rejects submissions the charity
/// would have been glad to receive.
class Validate {
  Validate._();

  static String? required(String? value, {String field = 'This field'}) {
    return (value == null || value.trim().isEmpty) ? '$field is required.' : null;
  }

  static String? name(String? value) {
    final empty = required(value, field: 'Your name');
    if (empty != null) return empty;

    return value!.trim().length < 2 ? 'Please enter your full name.' : null;
  }

  /// Deliberately not RFC 5322. Something before an @, something after it, and
  /// a dot in the domain catches every realistic typo without rejecting the
  /// perfectly valid addresses a stricter pattern would.
  static String? email(String? value, {bool optional = false}) {
    final trimmed = value?.trim() ?? '';

    if (trimmed.isEmpty) return optional ? null : 'Email address is required.';

    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(trimmed);

    return ok ? null : 'That does not look like an email address.';
  }

  /// Accepts 10-digit Indian mobiles with or without +91, spaces or dashes,
  /// and any international number of a plausible length.
  static String? phone(String? value, {bool optional = false}) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) return optional ? null : 'Phone number is required.';
    if (digits.length < 10) return 'Please enter a complete phone number.';
    if (digits.length > 15) return 'That phone number is too long.';

    return null;
  }

  /// ABCDE1234F. Required by law on Indian donations above the PAN threshold,
  /// so the format check is worth doing before the server refuses.
  static String? pan(String? value, {bool optional = false}) {
    final trimmed = (value ?? '').trim().toUpperCase();

    if (trimmed.isEmpty) return optional ? null : 'PAN is required for this amount.';

    return RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(trimmed)
        ? null
        : 'A PAN looks like ABCDE1234F.';
  }

  static String? minWords(String? value, int words, {String field = 'This'}) {
    final count = (value ?? '').trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

    return count >= words ? null : '$field needs at least $words words.';
  }

  static String? amount(String? value, {int min = 1}) {
    final parsed = int.tryParse((value ?? '').replaceAll(RegExp(r'[^0-9]'), ''));

    if (parsed == null || parsed == 0) return 'Enter an amount.';

    return parsed < min ? 'The smallest donation is ₹$min.' : null;
  }

  /// Chains validators, returning the first complaint.
  static String? all(List<String? Function()> checks) {
    for (final check in checks) {
      final error = check();
      if (error != null) return error;
    }

    return null;
  }
}
