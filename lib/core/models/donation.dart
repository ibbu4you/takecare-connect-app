/// Donations: what the form needs, what checkout returns, and what polling
/// tells us afterwards.
library;

class DonationOptions {
  const DonationOptions({
    this.currencies = const ['INR'],
    this.panThreshold = 10000,
    this.suggestedAmounts = const [500, 1000, 2500, 5000, 10000],
    this.donationsOpen = true,
    this.internationalEnabled = false,
  });

  final List<String> currencies;

  /// Above this, an Indian donation legally needs a PAN.
  final int panThreshold;

  final List<int> suggestedAmounts;

  /// Branch on this, never on `currencies` being empty — the server always
  /// returns at least INR, even when donations are closed.
  final bool donationsOpen;

  final bool internationalEnabled;

  factory DonationOptions.fromJson(Map<String, dynamic> json) => DonationOptions(
        currencies: ((json['currencies'] as List?) ?? const ['INR'])
            .map((e) => e.toString())
            .toList(),
        panThreshold: (json['pan_threshold'] ?? 10000) as int,
        suggestedAmounts: ((json['suggested_amounts'] as List?) ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
        donationsOpen: (json['donations_open'] ?? true) as bool,
        internationalEnabled: (json['international_enabled'] ?? false) as bool,
      );
}

/// What the server hands back when a checkout has been created.
///
/// Every field but [gateway] and [reference] is nullable: the payload is built
/// with the nulls stripped, and which keys arrive depends entirely on which
/// gateway took the order.
class CheckoutHandoff {
  const CheckoutHandoff({
    required this.gateway,
    required this.reference,
    this.orderId,
    this.sessionId,
    this.redirectUrl,
    this.publishableKey,
    this.environment,
  });

  final String gateway;

  /// The opaque handle to poll afterwards.
  final String reference;

  final String? orderId;

  /// Cashfree: opens its native SDK.
  final String? sessionId;

  /// Stripe: a hosted checkout page, opened in the external browser.
  final String? redirectUrl;

  final String? publishableKey;
  final String? environment;

  bool get isCashfree => gateway == 'cashfree';

  factory CheckoutHandoff.fromJson(Map<String, dynamic> json) => CheckoutHandoff(
        gateway: (json['gateway'] ?? '') as String,
        reference: (json['reference'] ?? '') as String,
        orderId: json['orderId'] as String?,
        sessionId: json['sessionId'] as String?,
        redirectUrl: json['redirectUrl'] as String?,
        publishableKey: json['publishableKey'] as String?,
        environment: json['environment'] as String?,
      );
}

class DonationStatus {
  const DonationStatus({
    required this.status,
    this.isPending = true,
    this.amount = 0,
    this.currency = 'INR',
    this.campaignSlug,
    this.receiptNumber,
    this.receiptUrl,
    this.paidAt,
    this.isRecurring = false,
  });

  final String status;
  final bool isPending;
  final double amount;
  final String currency;
  final String? campaignSlug;
  final String? receiptNumber;

  /// A signed, expiring link to the donor's own 80G receipt PDF.
  ///
  /// Null until the file exists — it is written by a queued job once the
  /// webhook confirms payment, so a donor who polls seconds after paying will
  /// legitimately have a receipt *number* and no document yet. The download is
  /// offered only when this is present.
  final String? receiptUrl;

  final DateTime? paidAt;
  final bool isRecurring;

  bool get hasReceipt => (receiptUrl?.isNotEmpty ?? false);

  bool get isPaid => status == 'paid';

  bool get hasFailed => status == 'failed';

  factory DonationStatus.fromJson(Map<String, dynamic> json) => DonationStatus(
        status: (json['status'] ?? 'created') as String,
        isPending: (json['is_pending'] ?? true) as bool,
        amount: ((json['amount'] ?? 0) as num).toDouble(),
        currency: (json['currency'] ?? 'INR') as String,
        campaignSlug: json['campaign_slug'] as String?,
        receiptNumber: json['receipt_number'] as String?,
        receiptUrl: json['receipt_url'] as String?,
        paidAt: DateTime.tryParse((json['paid_at'] ?? '') as String),
        isRecurring: (json['is_recurring'] ?? false) as bool,
      );
}
