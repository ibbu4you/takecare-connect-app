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
  const Photo({required this.url, this.alt = '', this.width, this.height});

  final String url;
  final String alt;
  final int? width;
  final int? height;

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
      );
}

class Product {
  const Product({
    required this.name,
    this.description,
    this.priceMin,
    this.priceMax,
    this.currency = 'INR',
    this.materials,
    this.howMade,
    this.whereToBuy,
    this.image,
  });

  final String name;
  final String? description;
  final double? priceMin;
  final double? priceMax;
  final String currency;
  final String? materials;
  final String? howMade;
  final String? whereToBuy;
  final String? image;

  bool get hasPrice => priceMin != null || priceMax != null;

  bool get hasDetails =>
      (materials?.isNotEmpty ?? false) ||
      (howMade?.isNotEmpty ?? false) ||
      (whereToBuy?.isNotEmpty ?? false);

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        name: (json['name'] ?? '') as String,
        description: json['description'] as String?,
        priceMin: _toDouble(json['price_min']),
        priceMax: _toDouble(json['price_max']),
        currency: (json['currency'] ?? 'INR') as String,
        materials: json['materials'] as String?,
        howMade: json['how_made'] as String?,
        whereToBuy: json['where_to_buy'] as String?,
        image: json['image'] as String?,
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

class BusinessDetail {
  const BusinessDetail({
    required this.slug,
    required this.name,
    this.ownerName,
    this.intro,
    this.body,
    this.faqs = const [],
    this.gallery = const [],
    this.products = const [],
    required this.contact,
    this.category,
    this.city,
    this.author,
    this.publishedAt,
  });

  final String slug;
  final String name;
  final String? ownerName;

  /// Both raw HTML.
  final String? intro;
  final String? body;

  final List<Faq> faqs;
  final List<Photo> gallery;
  final List<Product> products;
  final BusinessContact contact;
  final Taxonomy? category;
  final CityRef? city;
  final AuthorRef? author;
  final DateTime? publishedAt;

  factory BusinessDetail.fromJson(Map<String, dynamic> json) => BusinessDetail(
        slug: (json['slug'] ?? '') as String,
        name: (json['name'] ?? '') as String,
        ownerName: json['owner_name'] as String?,
        intro: json['intro'] as String?,
        body: json['body'] as String?,
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
