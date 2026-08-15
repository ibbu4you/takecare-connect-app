/// A crowdfunding campaign.
library;

class CampaignUpdate {
  const CampaignUpdate({required this.title, this.body, this.publishedAt});

  final String title;
  final String? body;
  final DateTime? publishedAt;

  factory CampaignUpdate.fromJson(Map<String, dynamic> json) => CampaignUpdate(
        title: (json['title'] ?? '') as String,
        body: json['body'] as String?,
        publishedAt: DateTime.tryParse((json['published_at'] ?? '') as String),
      );
}

class FundUsageRow {
  const FundUsageRow({required this.label, this.amount, this.note});

  final String label;
  final double? amount;
  final String? note;

  factory FundUsageRow.fromJson(Map<String, dynamic> json) => FundUsageRow(
        label: (json['label'] ?? '') as String,
        amount: json['amount'] == null ? null : (json['amount'] as num).toDouble(),
        note: json['note'] as String?,
      );
}

class Campaign {
  const Campaign({
    required this.slug,
    required this.title,
    required this.excerpt,
    this.image,
    this.goalAmount = 0,
    this.raisedAmount = 0,
    this.currency = 'INR',
    this.progressPercent = 0,
    this.isOpen = false,
    this.endsAt,
    this.story,
    this.fundUsage = const [],
    this.updates = const [],
    this.businessName,
    this.businessSlug,
    this.donorCount = 0,
  });

  final String slug;
  final String title;
  final String excerpt;
  final String? image;
  final double goalAmount;
  final double raisedAmount;
  final String currency;
  final double progressPercent;
  final bool isOpen;
  final DateTime? endsAt;

  /// Detail only — raw HTML.
  final String? story;
  final List<FundUsageRow> fundUsage;
  final List<CampaignUpdate> updates;
  final String? businessName;
  final String? businessSlug;
  final int donorCount;

  /// Null when the campaign has no closing date, which is different from zero.
  int? get daysRemaining {
    if (endsAt == null) return null;

    final days = endsAt!.difference(DateTime.now()).inDays;

    return days < 0 ? 0 : days;
  }

  /// Clamped, because a campaign can raise more than it asked for and a
  /// progress bar past 100% draws outside its track.
  double get progressFraction => (progressPercent / 100).clamp(0.0, 1.0);

  factory Campaign.fromJson(Map<String, dynamic> json) {
    final business = json['business'] as Map<String, dynamic>?;

    return Campaign(
      slug: (json['slug'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      excerpt: (json['excerpt'] ?? '') as String,
      image: json['image'] as String?,
      goalAmount: ((json['goal_amount'] ?? 0) as num).toDouble(),
      raisedAmount: ((json['raised_amount'] ?? 0) as num).toDouble(),
      currency: (json['currency'] ?? 'INR') as String,
      progressPercent: ((json['progress_percent'] ?? 0) as num).toDouble(),
      isOpen: (json['is_open'] ?? false) as bool,
      endsAt: DateTime.tryParse((json['ends_at'] ?? '') as String),
      story: json['story'] as String?,
      fundUsage: ((json['fund_usage'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(FundUsageRow.fromJson)
          .toList(),
      updates: ((json['updates'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CampaignUpdate.fromJson)
          .toList(),
      businessName: business?['name'] as String?,
      businessSlug: business?['slug'] as String?,
      donorCount: (json['donor_count'] ?? 0) as int,
    );
  }
}
