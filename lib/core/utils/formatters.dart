import 'package:intl/intl.dart';

/// Number and date formatting, in the conventions an Indian reader expects.
class Fmt {
  Fmt._();

  /// ₹1,23,456 — the Indian grouping, not the Western one.
  ///
  /// `NumberFormat.currency(locale: 'en_IN')` gives 1,23,456 rather than
  /// 123,456, which is what the website prints and what a donor reads without
  /// having to count digits.
  static final _rupees = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final _rupeesPrecise = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final _plain = NumberFormat.decimalPattern('en_IN');

  /// Money for display. Paise are dropped unless they exist — a campaign
  /// raising ₹45,000.00 should read ₹45,000.
  static String money(num amount, {String currency = 'INR'}) {
    if (currency != 'INR') {
      return NumberFormat.simpleCurrency(name: currency, decimalDigits: 0).format(amount);
    }

    return amount % 1 == 0 ? _rupees.format(amount) : _rupeesPrecise.format(amount);
  }

  static String count(num value) => _plain.format(value);

  /// ₹1.2L / ₹85K — for progress lines where the full figure would wrap.
  static String compactMoney(num amount) {
    if (amount >= 10000000) return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(0)}K';

    return money(amount);
  }

  /// 14 August 2026.
  static String date(DateTime? value) =>
      value == null ? '' : DateFormat('d MMMM y').format(value.toLocal());

  /// 14 Aug 2026 — for card metadata, where the long form crowds the byline.
  static String shortDate(DateTime? value) =>
      value == null ? '' : DateFormat('d MMM y').format(value.toLocal());

  /// "3 days ago" up to a fortnight, then the date.
  ///
  /// Relative time past a couple of weeks stops being useful — "47 days ago"
  /// makes a reader do arithmetic to learn something a date would have told
  /// them outright.
  static String relative(DateTime? value) {
    if (value == null) return '';

    final diff = DateTime.now().difference(value.toLocal());

    if (diff.isNegative) return shortDate(value);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 14) return '${diff.inDays} days ago';

    return shortDate(value);
  }

  /// "5 min read" — the API already computes this, so this is only a fallback.
  static String readingTime(int minutes) => '$minutes min read';
}
