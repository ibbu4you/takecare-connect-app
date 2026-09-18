library;

import 'business.dart';
import 'post.dart';

/// The shop: what our makers sell, and who they are.
///
/// Note what is not here, in any shape: a cart, a quantity, a basket, an order.
/// The foundation is not party to the sale — a buyer contacts the maker and the
/// two of them settle it between themselves — so there is nothing in this file
/// for a purchase to hang off, and that is deliberate rather than unfinished.
///
/// `priceLabel` arrives from the server already worded. The app never composes
/// it: "Ask the maker" is the foundation's phrase for a piece made to order,
/// and a client inventing its own wording is how two surfaces come to say
/// different things about the same pot.

/// Just enough of a maker to name them under a product.
class MakerRef {
  const MakerRef({required this.slug, required this.name, this.city});

  final String slug;
  final String name;
  final String? city;

  /// "Selvi Pottery, Khurja" — or just the name where we have no city.
  String get label => city == null || city!.isEmpty ? name : '$name, $city';

  static MakerRef? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    return MakerRef(
      slug: (json['slug'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      city: json['city'] as String?,
    );
  }
}

/// The three ways to reach a maker, each present only where they gave us one.
class MakerContact {
  const MakerContact({this.phone, this.whatsapp, this.email});

  final String? phone;

  /// A ready-made wa.me link, built server-side — never a bare number the app
  /// would have to guess the country code for.
  final String? whatsapp;
  final String? email;

  bool get hasPhone => phone?.isNotEmpty ?? false;
  bool get hasWhatsapp => whatsapp?.isNotEmpty ?? false;
  bool get hasEmail => email?.isNotEmpty ?? false;
  bool get hasAny => hasPhone || hasWhatsapp || hasEmail;

  factory MakerContact.fromJson(Map<String, dynamic>? json) => MakerContact(
        phone: json?['phone'] as String?,
        whatsapp: json?['whatsapp'] as String?,
        email: json?['email'] as String?,
      );
}

/// One product, as a card in a list.
class ShopProduct {
  const ShopProduct({
    required this.slug,
    required this.name,
    required this.priceLabel,
    this.tagline,
    this.priceMin,
    this.priceMax,
    this.currency = 'INR',
    this.unit,
    this.thumbnail,
    this.aiAssisted = false,
    this.category,
    this.maker,
  });

  final String slug;
  final String name;

  /// Already worded by the server — "₹450 / piece", "₹400 – ₹900", or
  /// "Ask the maker". Printed as given.
  final String priceLabel;

  final String? tagline;
  final double? priceMin;
  final double? priceMax;
  final String currency;
  final String? unit;
  final String? thumbnail;

  /// Whether a machine tidied the photograph up. Said out loud wherever the
  /// picture is shown, as on the website.
  final bool aiAssisted;

  final Taxonomy? category;
  final MakerRef? maker;

  factory ShopProduct.fromJson(Map<String, dynamic> json) => ShopProduct(
        slug: (json['slug'] ?? '') as String,
        name: (json['name'] ?? '') as String,
        priceLabel: (json['price_label'] ?? 'Ask the maker') as String,
        tagline: json['tagline'] as String?,
        priceMin: _toDouble(json['price_min']),
        priceMax: _toDouble(json['price_max']),
        currency: (json['currency'] ?? 'INR') as String,
        unit: json['unit'] as String?,
        thumbnail: json['thumbnail'] as String?,
        aiAssisted: (json['ai_assisted'] ?? false) as bool,
        category: Taxonomy.fromJson(json['category'] as Map<String, dynamic>?),
        maker: MakerRef.fromJson(json['maker'] as Map<String, dynamic>?),
      );
}

/// The maker, as a product page introduces them.
class ProductMaker {
  const ProductMaker({
    required this.slug,
    required this.name,
    required this.contact,
    this.ownerName,
    this.blurb,
    this.city,
    this.logo,
    this.sinceYear,
    this.interviewSlug,
  });

  final String slug;
  final String name;
  final MakerContact contact;
  final String? ownerName;
  final String? blurb;
  final String? city;
  final String? logo;

  /// How long they have been with us. A fact, which is more than "verified"
  /// would be — see the note on [Brand].
  final int? sinceYear;

  /// Null unless we published an interview with them. A craftsman who applied
  /// to sell has a shop page and no article, and offering to open one that does
  /// not exist is worse than not offering.
  final String? interviewSlug;

  bool get hasInterview => interviewSlug != null && interviewSlug!.isNotEmpty;

  static ProductMaker? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    return ProductMaker(
      slug: (json['slug'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      contact: MakerContact.fromJson(json['contact'] as Map<String, dynamic>?),
      ownerName: json['owner_name'] as String?,
      blurb: json['blurb'] as String?,
      city: json['city'] as String?,
      logo: json['logo'] as String?,
      sinceYear: json['since_year'] as int?,
      interviewSlug: json['interview_slug'] as String?,
    );
  }
}

/// One product's own page.
class ShopProductDetail {
  const ShopProductDetail({
    required this.slug,
    required this.name,
    required this.priceLabel,
    this.tagline,
    this.unit,
    this.description,
    this.materials,
    this.howMade,
    this.whereToBuy,
    this.highlights = const [],
    this.images = const [],
    this.category,
    this.maker,
    this.canEnquire = false,
    this.canCall = false,
    this.alsoBy = const [],
  });

  final String slug;
  final String name;
  final String priceLabel;
  final String? tagline;
  final String? unit;

  /// All raw HTML.
  final String? description;
  final String? materials;
  final String? howMade;
  final String? whereToBuy;

  final List<String> highlights;
  final List<Photo> images;
  final Taxonomy? category;
  final ProductMaker? maker;

  /// Two flags, never one, and both decided by the server.
  ///
  /// Whether an enquiry reaches anybody depends on fields this payload does not
  /// carry, so the app cannot work it out. One flag for both once put "View
  /// their number" in front of a maker with an email and no phone, on the
  /// website: it took the buyer's details and had nothing to hand back.
  final bool canEnquire;
  final bool canCall;

  final List<ShopProduct> alsoBy;

  /// Whether any picture here was machine-tidied, so the note can be shown once
  /// under the gallery rather than on every frame.
  bool get anyAiAssisted => images.any((image) => image.aiAssisted);

  bool get hasDetails =>
      (materials?.isNotEmpty ?? false) ||
      (howMade?.isNotEmpty ?? false) ||
      (whereToBuy?.isNotEmpty ?? false);

  factory ShopProductDetail.fromJson(Map<String, dynamic> json) => ShopProductDetail(
        slug: (json['slug'] ?? '') as String,
        name: (json['name'] ?? '') as String,
        priceLabel: (json['price_label'] ?? 'Ask the maker') as String,
        tagline: json['tagline'] as String?,
        unit: json['unit'] as String?,
        description: json['description'] as String?,
        materials: json['materials'] as String?,
        howMade: json['how_made'] as String?,
        whereToBuy: json['where_to_buy'] as String?,
        highlights: ((json['highlights'] as List?) ?? const [])
            .map((line) => line.toString())
            .where((line) => line.isNotEmpty)
            .toList(),
        images: ((json['images'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(Photo.fromJson)
            .toList(),
        category: Taxonomy.fromJson(json['category'] as Map<String, dynamic>?),
        maker: ProductMaker.fromJson(json['maker'] as Map<String, dynamic>?),
        canEnquire: (json['can_enquire'] ?? false) as bool,
        canCall: (json['can_call'] ?? false) as bool,
        alsoBy: ((json['also_by'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ShopProduct.fromJson)
            .toList(),
      );
}

/// A maker in the directory.
///
/// Every field is a fact the foundation can stand behind: their craft, their
/// city, how many things they list, how long they have been with us, and
/// whether we published an interview. Nobody is verified and nobody is
/// certified — that would turn a listing into a guarantee of somebody's goods —
/// and no payment is secured here, because no money passes through this app.
class Brand {
  const Brand({
    required this.slug,
    required this.name,
    required this.contact,
    this.ownerName,
    this.blurb,
    this.logo,
    this.banner,
    this.image,
    this.city,
    this.craft,
    this.productCount,
    this.sinceYear,
    this.interviewSlug,
    this.products = const [],
  });

  final String slug;
  final String name;
  final MakerContact contact;
  final String? ownerName;
  final String? blurb;
  final String? logo;
  final String? banner;

  /// A photograph from their interview, where there is one. The fallback for a
  /// maker who has uploaded no logo: a shop with no mark should read as a shop
  /// with no mark, not as one whose picture failed to load.
  final String? image;

  final CityRef? city;
  final Taxonomy? craft;
  final int? productCount;
  final int? sinceYear;
  final String? interviewSlug;

  /// Their shelf. Empty on the directory card; filled on their own page.
  final List<ShopProduct> products;

  bool get hasInterview => interviewSlug != null && interviewSlug!.isNotEmpty;

  /// Whatever mark we can show for them, in order of what they chose
  /// themselves.
  String? get mark => logo ?? image ?? banner;

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
        slug: (json['slug'] ?? '') as String,
        name: (json['name'] ?? '') as String,
        contact: MakerContact.fromJson(json['contact'] as Map<String, dynamic>?),
        ownerName: json['owner_name'] as String?,
        blurb: json['blurb'] as String?,
        logo: json['logo'] as String?,
        banner: json['banner'] as String?,
        image: json['image'] as String?,
        city: CityRef.fromJson(json['city'] as Map<String, dynamic>?),
        craft: Taxonomy.fromJson(json['craft'] as Map<String, dynamic>?),
        productCount: json['product_count'] as int?,
        sinceYear: json['since_year'] as int?,
        interviewSlug: json['interview_slug'] as String?,
        products: ((json['products'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ShopProduct.fromJson)
            .toList(),
      );
}

/// Everything the filter sheet needs, in one request.
///
/// All three lists are [TaxonomyOption]s, which the stories and craftsmen
/// filters already use — a slug, a name and a count is the same shape whether
/// the thing being counted is a craft, a city or a maker.
///
/// Only crafts, cities and makers that actually have something for sale are
/// offered: a tick that empties the page makes a visitor blame the app rather
/// than the filter, so the server does not hand one over.
class ShopFilters {
  const ShopFilters({
    this.categories = const [],
    this.cities = const [],
    this.makers = const [],
  });

  final List<TaxonomyOption> categories;
  final List<TaxonomyOption> cities;
  final List<TaxonomyOption> makers;

  bool get isEmpty => categories.isEmpty && cities.isEmpty && makers.isEmpty;

  factory ShopFilters.fromJson(Map<String, dynamic> json) {
    List<TaxonomyOption> options(String key) => ((json[key] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(TaxonomyOption.fromJson)
        .toList();

    return ShopFilters(
      categories: options('categories'),
      cities: options('cities'),
      makers: options('makers'),
    );
  }
}

/// JSON numbers arrive as int or double depending on whether they had a
/// fractional part, and prices come off a decimal column as strings.
double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();

  return double.tryParse(value.toString());
}
