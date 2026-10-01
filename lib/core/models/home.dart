library;

import 'business.dart';
import 'campaign.dart';
import 'post.dart';
import 'shop.dart';

/// Everything the Home tab draws, in one payload.
///
/// Composed server-side deliberately: a phone on a patchy connection should not
/// make six requests to fill one screen.

/// How much shade a banner asks the app to draw over its picture.
///
/// A token the office sets, not a decision the app makes: the same photograph
/// needs different treatment depending on what was written over it, and only
/// the person who wrote it knows. An image-only slide always reports [none].
enum BannerOverlay {
  none,
  light,
  standard,
  heavy;

  static BannerOverlay parse(String? value) => switch (value) {
        'none' => BannerOverlay.none,
        'light' => BannerOverlay.light,
        'heavy' => BannerOverlay.heavy,
        // Anything unrecognised, and the absent case on an older server, get
        // the gradient every banner wore before the field existed.
        _ => BannerOverlay.standard,
      };
}

class BannerSlide {
  const BannerSlide({
    this.eyebrow,
    this.title,
    this.subtitle,
    this.image,
    this.mobileImage,
    this.imageAlt,
    this.overlay = BannerOverlay.standard,
    this.isImageOnly = false,
    this.ctaLabel,
    this.ctaUrl,
    this.secondaryCtaLabel,
    this.secondaryCtaUrl,
  });

  final String? eyebrow;
  final String? title;
  final String? subtitle;
  final String? image;
  final String? mobileImage;

  /// What the picture shows, in the office's own words.
  ///
  /// The only label a designed banner has: its words are inside the artwork,
  /// where a screen reader cannot reach them, and without this it would be read
  /// out as a ULID filename.
  final String? imageAlt;

  final BannerOverlay overlay;

  /// A designed banner whose artwork carries its own words — no scrim, no
  /// overlaid copy.
  final bool isImageOnly;

  final String? ctaLabel;
  final String? ctaUrl;

  /// The quieter of two buttons. Served since the footer banner shipped and
  /// never drawn until now.
  final String? secondaryCtaLabel;
  final String? secondaryCtaUrl;

  /// Prefer the portrait crop on a phone; the wide one is cropped to its
  /// middle otherwise, which cuts the words out of a designed banner.
  String? get bestImage => mobileImage ?? image;

  bool get hasCta => (ctaLabel?.isNotEmpty ?? false) && (ctaUrl?.isNotEmpty ?? false);

  bool get hasSecondaryCta =>
      (secondaryCtaLabel?.isNotEmpty ?? false) && (secondaryCtaUrl?.isNotEmpty ?? false);

  /// What a screen reader should be told, falling back to whatever copy there
  /// is rather than to nothing.
  String? get semanticLabel => imageAlt?.isNotEmpty == true ? imageAlt : title;

  factory BannerSlide.fromJson(Map<String, dynamic> json) {
    final cta = json['cta'] as Map<String, dynamic>?;
    final secondary = json['secondary_cta'] as Map<String, dynamic>?;

    return BannerSlide(
      eyebrow: json['eyebrow'] as String?,
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      image: json['image'] as String?,
      mobileImage: json['mobile_image'] as String?,
      imageAlt: json['image_alt'] as String?,
      overlay: BannerOverlay.parse(json['overlay'] as String?),
      isImageOnly: (json['is_image_only'] ?? false) as bool,
      ctaLabel: cta?['label'] as String?,
      ctaUrl: cta?['url'] as String?,
      secondaryCtaLabel: secondary?['label'] as String?,
      secondaryCtaUrl: secondary?['url'] as String?,
    );
  }
}

class CategorySection {
  const CategorySection({
    required this.slug,
    required this.name,
    this.description,
    this.posts = const [],
  });

  final String slug;
  final String name;
  final String? description;
  final List<PostSummary> posts;

  factory CategorySection.fromJson(Map<String, dynamic> json) => CategorySection(
        slug: (json['slug'] ?? '') as String,
        name: (json['name'] ?? '') as String,
        description: json['description'] as String?,
        posts: ((json['posts'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(PostSummary.fromJson)
            .toList(),
      );
}

/// The photographs behind the landing page's fixed sections.
///
/// Their words are written into the app, as they are into the website's
/// Home.tsx; their pictures are the website's own files, sent as full URLs so
/// that replacing one on the website changes the app with no release. Null on
/// an older server, and each section then draws without its picture.
class LandingImages {
  const LandingImages({
    this.whoWeAre,
    this.craftsmanship,
    this.events,
    this.crowdfunding,
    this.stories,
    this.vision,
  });

  final String? whoWeAre;
  final String? craftsmanship;
  final String? events;
  final String? crowdfunding;
  final String? stories;
  final String? vision;

  factory LandingImages.fromJson(Map<String, dynamic>? json) {
    final pillars = json?['pillars'] as Map<String, dynamic>?;

    return LandingImages(
      whoWeAre: json?['who_we_are'] as String?,
      craftsmanship: pillars?['craftsmanship'] as String?,
      events: pillars?['events'] as String?,
      crowdfunding: pillars?['crowdfunding'] as String?,
      stories: pillars?['stories'] as String?,
      vision: json?['vision'] as String?,
    );
  }
}

class HomePayload {
  const HomePayload({
    this.banners = const [],
    this.featuredStories = const [],
    this.featuredCraftsmen = const [],
    this.featuredProducts = const [],
    this.landingImages = const LandingImages(),
    this.activeCampaigns = const [],
    this.categorySections = const [],
    this.footerBanner,
  });

  final List<BannerSlide> banners;

  final List<PostSummary> featuredStories;
  final List<BusinessSummary> featuredCraftsmen;

  /// The website's Shop row. Empty on an older server, and the band is left out.
  final List<ShopProduct> featuredProducts;

  final LandingImages landingImages;

  final List<Campaign> activeCampaigns;

  /// One rail per subject on the website; in the app these are the tabs over
  /// the stories band, which is how the website presents them too.
  final List<CategorySection> categorySections;

  /// The strip the website carries above its footer. Drawn at the foot of Home
  /// rather than under every screen — a promotional band under every article is
  /// where people stop scrolling.
  final BannerSlide? footerBanner;

  /*
   | Every list defaults to empty and every object to null.
   |
   | Not defensiveness for its own sake: it is what lets a new app run against
   | an older server. Each of these bands arrived after 1.0.1 shipped, so a
   | build pointed at a site that has not been deployed yet draws the screen it
   | can and leaves out the rest, instead of throwing on a missing key.
   */
  factory HomePayload.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) =>
        ((json[key] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(parse)
            .toList();

    final footer = json['footer_banner'] as Map<String, dynamic>?;

    return HomePayload(
      banners: list('banners', BannerSlide.fromJson),
      featuredStories: list('featured_stories', PostSummary.fromJson),
      featuredCraftsmen: list('featured_craftsmen', BusinessSummary.fromJson),
      featuredProducts: list('featured_products', ShopProduct.fromJson),
      landingImages: LandingImages.fromJson(json['landing_images'] as Map<String, dynamic>?),
      activeCampaigns: list('active_campaigns', Campaign.fromJson),
      categorySections: list('category_sections', CategorySection.fromJson),
      footerBanner: footer == null ? null : BannerSlide.fromJson(footer),
    );
  }
}
