import 'post.dart';

/// A craftsman interview, and the things they sell.

class BusinessSummary {
  const BusinessSummary({
    required this.slug,
    required this.name,
    required this.excerpt,
    this.ownerName,
    this.thumbnail,
    this.category,
    this.city,
    this.publishedAt,
  });

  final String slug;
  final String name;
  final String excerpt;
  final String? ownerName;
  final String? thumbnail;
  final Taxonomy? category;
  final CityRef? city;
  final DateTime? publishedAt;

  factory BusinessSummary.fromJson(Map<String, dynamic> json) => BusinessSummary(
        slug: (json['slug'] ?? '') as String,
        name: (json['name'] ?? '') as String,
        excerpt: (json['excerpt'] ?? '') as String,
        ownerName: json['owner_name'] as String?,
        thumbnail: json['thumbnail'] as String?,
        category: Taxonomy.fromJson(json['category'] as Map<String, dynamic>?),
        city: CityRef.fromJson(json['city'] as Map<String, dynamic>?),
        publishedAt: DateTime.tryParse((json['published_at'] ?? '') as String),
      );
}

class CityRef {
  const CityRef({required this.slug, required this.name, this.state});

  final String slug;
  final String name;
  final String? state;

  static CityRef? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    return CityRef(
      slug: (json['slug'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      state: json['state'] as String?,
    );
  }
}

class Photo {
  const Photo({
    required this.url,
    this.alt = '',
    this.width,
    this.height,
    this.aiAssisted = false,
  });

  final String url;
  final String alt;
  final int? width;
  final int? height;

  /// Whether a machine tidied this photograph up.
  ///
  /// Said out loud wherever the picture is shown, as the website says it. The
  /// object in the frame is always the real one — only the background, the
  /// light and the framing are the machine's work — and mentioning it costs
  /// nothing next to explaining later why nobody did.
  final bool aiAssisted;

  /// Null when either dimension is missing, so a caller can fall back rather
  /// than divide by zero.
  double? get aspectRatio {
    if (width == null || height == null || height == 0) return null;

    return width! / height!;
  }

  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
        url: (json['url'] ?? '') as String,
        alt: (json['alt'] ?? '') as String,
        width: json['width'] as int?,
        height: json['height'] as int?,
        aiAssisted: (json['ai_assisted'] ?? false) as bool,
      );
}

class Product {
  const Product({
    required this.name,
    this.slug,
    this.tagline,
    this.description,
    this.priceMin,
    this.priceMax,
    this.currency = 'INR',
    this.priceLabel = 'Ask the maker',
    this.unit,
    this.highlights = const [],
    this.materials,
    this.howMade,
    this.whereToBuy,
    this.image,
    this.aiAssisted = false,
  });

  final String name;

  /// Null on an older server, which is why the rail only offers to open a
  /// product when there is one: the route it needs is /shop/{slug}, and this
  /// payload predates the shop existing.
  final String? slug;

  final String? tagline;
  final String? description;
  final double? priceMin;
  final double? priceMax;
  final String currency;

  /// Worded by the server. See the note at the top of models/shop.dart.
  final String priceLabel;

  final String? unit;
  final List<String> highlights;
  final String? materials;
  final String? howMade;
  final String? whereToBuy;
  final String? image;
  final bool aiAssisted;

  bool get canOpen => slug != null && slug!.isNotEmpty;

  bool get hasPrice => priceMin != null || priceMax != null;

  bool get hasDetails =>
      (materials?.isNotEmpty ?? false) ||
      (howMade?.isNotEmpty ?? false) ||
      (whereToBuy?.isNotEmpty ?? false);

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        name: (json['name'] ?? '') as String,
        slug: json['slug'] as String?,
        tagline: json['tagline'] as String?,
        description: json['description'] as String?,
        priceMin: _toDouble(json['price_min']),
        priceMax: _toDouble(json['price_max']),
        currency: (json['currency'] ?? 'INR') as String,
        priceLabel: (json['price_label'] ?? 'Ask the maker') as String,
        unit: json['unit'] as String?,
        highlights: ((json['highlights'] as List?) ?? const [])
            .map((line) => line.toString())
            .where((line) => line.isNotEmpty)
            .toList(),
        materials: json['materials'] as String?,
        howMade: json['how_made'] as String?,
        whereToBuy: json['where_to_buy'] as String?,
        image: json['image'] as String?,
        aiAssisted: (json['ai_assisted'] ?? false) as bool,
      );
}

class BusinessContact {
  const BusinessContact({this.phone, this.email, this.address, this.latitude, this.longitude});

  final String? phone;
  final String? email;
  final String? address;
  final double? latitude;
  final double? longitude;

  /// Whether the sidebar can offer to reveal a number.
  ///
  /// Almost every imported craftsman has none: the old WordPress site's "View
  /// Number" button opened a form asking the *reader* for their number, so the
  /// craftsman's own was never stored. The app must handle null gracefully
  /// rather than treat it as the exception.
  bool get hasPhone => (phone?.isNotEmpty ?? false);

  factory BusinessContact.fromJson(Map<String, dynamic>? json) => BusinessContact(
        phone: json?['phone'] as String?,
        email: json?['email'] as String?,
        address: json?['address'] as String?,
        latitude: _toDouble(json?['latitude']),
        longitude: _toDouble(json?['longitude']),
      );
}

class Faq {
  const Faq({required this.question, required this.answer});

  final String question;
  final String answer;

  factory Faq.fromJson(Map<String, dynamic> json) => Faq(
        question: (json['question'] ?? '') as String,
        answer: (json['answer'] ?? '') as String,
      );
}

/// The maker's shop, linked from their interview.
///
/// Null for a craftsman we only interviewed — plenty of them have no shop, and
/// that is not a gap in the record.
class BusinessBrand {
  const BusinessBrand({
    required this.slug,
    required this.name,
    this.blurb,
    this.logo,
    this.banner,
    this.productCount,
  });

  final String slug;
  final String name;
  final String? blurb;
  final String? logo;
  final String? banner;
  final int? productCount;

  static BusinessBrand? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    return BusinessBrand(
      slug: (json['slug'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      blurb: json['blurb'] as String?,
      logo: json['logo'] as String?,
      banner: json['banner'] as String?,
      productCount: json['product_count'] as int?,
    );
  }
}

class BusinessDetail {
  const BusinessDetail({
    required this.slug,
    required this.name,
    this.headline,
    this.ownerName,
    this.intro,
    this.body,
    this.readingMinutes,
    this.faqs = const [],
    this.gallery = const [],
    this.products = const [],
    required this.contact,
    this.category,
    this.city,
    this.author,
    this.brand,
    this.canEnquire = false,
    this.canCall = false,
    this.publishedAt,
  });

  final String slug;
  final String name;

  /// The editorial line above the article. Falls back to the name on the
  /// server, so this is never empty where a name exists.
  final String? headline;

  final String? ownerName;

  /// Both raw HTML.
  final String? intro;
  final String? body;

  final int? readingMinutes;

  final List<Faq> faqs;
  final List<Photo> gallery;
  final List<Product> products;
  final BusinessContact contact;
  final Taxonomy? category;
  final CityRef? city;
  final AuthorRef? author;
  final BusinessBrand? brand;

  /// Whether either button is worth drawing, as decided by the server.
  ///
  /// The app cannot work this out: whether an enquiry lands in anybody's inbox
  /// depends on the maker's email and on an office fallback address, neither of
  /// which travels in this payload. Before these existed the app drew both
  /// buttons regardless, so a reader could fill in a form that had nowhere to
  /// go. Prefer these over [BusinessContact.hasPhone].
  final bool canEnquire;
  final bool canCall;

  final DateTime? publishedAt;

  factory BusinessDetail.fromJson(Map<String, dynamic> json) => BusinessDetail(
        slug: (json['slug'] ?? '') as String,
        name: (json['name'] ?? '') as String,
        headline: json['headline'] as String?,
        ownerName: json['owner_name'] as String?,
        intro: json['intro'] as String?,
        body: json['body'] as String?,
        readingMinutes: json['reading_minutes'] as int?,
        faqs: ((json['faqs'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(Faq.fromJson)
            .toList(),
        gallery: ((json['gallery'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(Photo.fromJson)
            .toList(),
        products: ((json['products'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(Product.fromJson)
            .toList(),
        contact: BusinessContact.fromJson(json['contact'] as Map<String, dynamic>?),
        category: Taxonomy.fromJson(json['category'] as Map<String, dynamic>?),
        city: CityRef.fromJson(json['city'] as Map<String, dynamic>?),
        author: AuthorRef.fromJson(json['author'] as Map<String, dynamic>?),
        brand: BusinessBrand.fromJson(json['brand'] as Map<String, dynamic>?),
        /*
         | Absent means yes, which is what the app did before these existed.
         |
         | Defaulting to false would be the tidier-looking choice and it is the
         | wrong one: a new build pointed at a server that has not been deployed
         | yet would lose the enquiry button altogether, which is a worse bug
         | than the one these flags fix. Where the server has an opinion it
         | wins, and a craftsman nothing would reach gets no button.
         |
         | `can_call` falls back to the number in the payload — the one thing
         | the app can check for itself.
         */
        canEnquire: (json['can_enquire'] ?? true) as bool,
        canCall: (json['can_call'] ?? false) as bool,
        publishedAt: DateTime.tryParse((json['published_at'] ?? '') as String),
      );
}

/// JSON numbers arrive as int or double depending on whether they had a
/// fractional part, and prices are sometimes strings from a decimal column.
double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();

  return double.tryParse(value.toString());
}
