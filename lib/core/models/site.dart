import 'campaign.dart';

/// Site-level content: settings, static pages, about, transparency, and the
/// option lists the forms render.

class PageContent {
  const PageContent({required this.slug, required this.title, this.body, this.updatedAtLabel});

  final String slug;
  final String title;
  final String? body;
  final String? updatedAtLabel;

  factory PageContent.fromJson(Map<String, dynamic> json) => PageContent(
        slug: (json['slug'] ?? '') as String,
        title: (json['title'] ?? '') as String,
        body: json['body'] as String?,
        updatedAtLabel: json['updated_at_label'] as String?,
      );
}

class SiteSettings {
  const SiteSettings({
    this.name = 'Take Care International Foundation',
    this.tagline = '',
    this.footerDescription = '',
    this.credentials = const [],
    this.email = '',
    this.phone = '',
    this.address = '',
    this.openingDays = '',
    this.mapEmbedUrl,
    this.social = const {},
  });

  final String name;
  final String tagline;
  final String footerDescription;

  /// "Section 8 Company", "12A", "80G" — what a donor checks before giving.
  final List<String> credentials;

  final String email;
  final String phone;
  final String address;
  final String openingDays;
  final String? mapEmbedUrl;
  final Map<String, String> social;

  factory SiteSettings.fromJson(Map<String, dynamic> json) {
    final site = (json['site'] as Map<String, dynamic>?) ?? const {};
    final contact = (json['contact'] as Map<String, dynamic>?) ?? const {};

    // `social` is keyed by network — but when the office has set none, PHP's
    // empty array serialises as `[]`, not `{}`, and a straight cast to a map
    // throws. That is not a hypothetical: it is what production returns today,
    // and it took the whole settings payload down with it — the footer, the
    // contact screen and the credentials under the donate button.
    final rawSocial = json['social'];
    final social = rawSocial is Map ? rawSocial : const {};

    return SiteSettings(
      name: (site['name'] ?? 'Take Care International Foundation') as String,
      tagline: (site['tagline'] ?? '') as String,
      footerDescription: (site['footer_description'] ?? '') as String,
      credentials: ((site['credentials'] as List?) ?? const []).map((e) => e.toString()).toList(),
      email: (contact['email'] ?? '') as String,
      phone: (contact['phone'] ?? '') as String,
      address: (contact['address'] ?? '') as String,
      openingDays: (contact['opening_days'] ?? '') as String,
      mapEmbedUrl: contact['map_embed_url'] as String?,
      social: {
        for (final entry in social.entries) entry.key.toString(): entry.value.toString(),
      },
    );
  }
}

/// One choice in a select, exactly as the server will validate it.
class Option {
  const Option({required this.value, required this.label});

  final String value;
  final String label;

  factory Option.fromJson(Map<String, dynamic> json) => Option(
        value: (json['value'] ?? '') as String,
        label: (json['label'] ?? '') as String,
      );
}

/// Every list the native forms need.
///
/// Fetched rather than hard-coded: the server validates these with `Rule::in`,
/// so a stale copy in the app means a 422 the reader cannot act on.
class FormOptions {
  const FormOptions({this.lists = const {}});

  final Map<String, List<Option>> lists;

  List<Option> operator [](String key) => lists[key] ?? const [];

  factory FormOptions.fromJson(Map<String, dynamic> json) => FormOptions(
        lists: json.map(
          (key, value) => MapEntry(
            key,
            ((value as List?) ?? const [])
                .whereType<Map<String, dynamic>>()
                .map(Option.fromJson)
                .toList(),
          ),
        ),
      );
}

class AboutBlock {
  const AboutBlock({required this.title, required this.body, this.icon});

  final String title;
  final String body;
  final String? icon;

  /// The two block lists on this page are not the same shape.
  ///
  /// A value carries `title` and a paragraph of `body`; a focus area carries
  /// only `label`. Reading `title` alone gives every focus area an empty
  /// heading — a column of blank cards, which is what production returns
  /// today.
  factory AboutBlock.fromJson(Map<String, dynamic> json) => AboutBlock(
        title: (json['title'] ?? json['label'] ?? '') as String,
        body: (json['body'] ?? json['description'] ?? '') as String,
        icon: json['icon'] as String?,
      );
}

class AboutStat {
  const AboutStat({required this.value, required this.label});

  final String value;
  final String label;

  factory AboutStat.fromJson(Map<String, dynamic> json) => AboutStat(
        value: (json['value'] ?? '') as String,
        label: (json['label'] ?? '') as String,
      );
}

class AboutContent {
  const AboutContent({
    required this.title,
    this.introHeading = '',
    this.introBody = '',
    this.introEyebrow = '',
    this.vision = '',
    this.mission = '',
    this.valuesLead = '',
    this.values = const [],
    this.focusHeading = '',
    this.focusLead = '',
    this.focusAreas = const [],
    this.stats = const [],
    this.extraBody,
  });

  final String title;
  final String introEyebrow;
  final String introHeading;
  final String introBody;
  final String vision;
  final String mission;
  final String valuesLead;
  final List<AboutBlock> values;
  final String focusHeading;
  final String focusLead;
  final List<AboutBlock> focusAreas;
  final List<AboutStat> stats;
  final String? extraBody;

  factory AboutContent.fromJson(Map<String, dynamic> json) {
    final intro = (json['intro'] as Map<String, dynamic>?) ?? const {};
    final values = (json['values'] as Map<String, dynamic>?) ?? const {};

    // `focusAreas`, not `focus_areas`. Every other key on this payload is
    // snake_case, but this block is spread verbatim from the Inertia props the
    // website's About page reads, and those are camelCase. Renaming it
    // server-side would break that page, so the odd one out is honoured here.
    final focus = (json['focusAreas'] as Map<String, dynamic>?) ??
        (json['focus_areas'] as Map<String, dynamic>?) ??
        const {};

    List<AboutBlock> blocks(dynamic raw) => ((raw as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AboutBlock.fromJson)
        .toList();

    return AboutContent(
      title: (json['title'] ?? 'About Us') as String,
      introEyebrow: (intro['eyebrow'] ?? '') as String,
      introHeading: (intro['heading'] ?? '') as String,
      introBody: (intro['body'] ?? '') as String,
      vision: (json['vision'] ?? '') as String,
      mission: (json['mission'] ?? '') as String,
      valuesLead: (values['lead'] ?? values['intro'] ?? '') as String,
      values: blocks(values['items']),
      focusHeading: (focus['heading'] ?? '') as String,
      focusLead: (focus['intro'] ?? '') as String,
      focusAreas: blocks(focus['items']),
      stats: ((json['stats'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AboutStat.fromJson)
          .toList(),
      extraBody: json['extra_body'] as String?,
    );
  }
}

class TransparencyLedgerRow {
  const TransparencyLedgerRow({
    required this.campaign,
    this.ledgerTotal = 0,
    this.donorCount = 0,
    this.reconciles = true,
  });

  final Campaign campaign;
  final double ledgerTotal;
  final int donorCount;

  /// False when the cached total and the ledger disagree. Surfaced rather than
  /// hidden — that is the point of the page.
  final bool reconciles;

  factory TransparencyLedgerRow.fromJson(Map<String, dynamic> json) => TransparencyLedgerRow(
        campaign: Campaign.fromJson(json),
        ledgerTotal: ((json['ledger_total'] ?? 0) as num).toDouble(),
        donorCount: (json['donor_count'] ?? 0) as int,
        reconciles: (json['reconciles'] ?? true) as bool,
      );
}

class TransparencyData {
  const TransparencyData({
    required this.title,
    this.body,
    this.allTime = 0,
    this.thisYear = 0,
    this.donationCount = 0,
    this.donorCount = 0,
    this.generalFund = 0,
    this.campaigns = const [],
  });

  final String title;
  final String? body;
  final double allTime;
  final double thisYear;
  final int donationCount;
  final int donorCount;
  final double generalFund;
  final List<TransparencyLedgerRow> campaigns;

  factory TransparencyData.fromJson(Map<String, dynamic> json) {
    final totals = (json['totals'] as Map<String, dynamic>?) ?? const {};

    return TransparencyData(
      title: (json['title'] ?? 'Transparency') as String,
      body: json['body'] as String?,
      allTime: ((totals['all_time'] ?? 0) as num).toDouble(),
      thisYear: ((totals['this_year'] ?? 0) as num).toDouble(),
      donationCount: (totals['donation_count'] ?? 0) as int,
      donorCount: (totals['donor_count'] ?? 0) as int,
      generalFund: ((totals['general_fund'] ?? 0) as num).toDouble(),
      campaigns: ((json['campaigns'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(TransparencyLedgerRow.fromJson)
          .toList(),
    );
  }
}
