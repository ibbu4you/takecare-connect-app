library;

import 'business.dart';
import 'campaign.dart';
import 'post.dart';

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

/// One counted figure from the impact band.
///
/// The value is a string on purpose — the server rounds ("1,000+") and one of
/// them is the word "One", for "One brighter India". Formatting it here would
/// mean parsing prose back into a number.
class ImpactStat {
  const ImpactStat({required this.value, required this.label});

  final String value;
  final String label;

  factory ImpactStat.fromJson(Map<String, dynamic> json) => ImpactStat(
        value: (json['value'] ?? '') as String,
        label: (json['label'] ?? '') as String,
      );
}

/// Somebody's words about the foundation, with their name against them.
class Testimonial {
  const Testimonial({
    required this.quote,
    this.authorName,
    this.authorRole,
    this.avatar,
    this.url,
  });

  final String quote;
  final String? authorName;
  final String? authorRole;

  /// Optional, and null rather than a placeholder: initials read better than a
  /// grey silhouette.
  final String? avatar;

  final String? url;

  factory Testimonial.fromJson(Map<String, dynamic> json) => Testimonial(
        quote: (json['quote'] ?? '') as String,
        authorName: json['author_name'] as String?,
        authorRole: json['author_role'] as String?,
        avatar: json['avatar'] as String?,
        url: json['url'] as String?,
      );
}

/// A subject a reader can browse by, with a cover picture and a count.
class PostCategoryTile {
  const PostCategoryTile({
    required this.slug,
    required this.name,
    this.description,
    this.count = 0,
    this.image,
  });

  final String slug;
  final String name;
  final String? description;
  final int count;

  /// Null until somebody uploads one; the tile draws itself in the category's
  /// own colour instead of leaving a gap.
  final String? image;

  /// "12 stories", or nothing at all for a subject nobody has written in yet —
  /// "0 stories" on a tile is worse than no line.
  String? get countLabel => count == 0 ? null : '$count ${count == 1 ? 'story' : 'stories'}';

  factory PostCategoryTile.fromJson(Map<String, dynamic> json) => PostCategoryTile(
        slug: (json['slug'] ?? '') as String,
        name: (json['name'] ?? '') as String,
        description: json['description'] as String?,
        count: (json['count'] ?? 0) as int,
        image: json['image'] as String?,
      );
}

/// The two photographs behind the invitation panels. Either may be absent, and
/// the panel draws its own field instead.
class PromoImages {
  const PromoImages({this.craft, this.discover});

  final String? craft;
  final String? discover;

  factory PromoImages.fromJson(Map<String, dynamic>? json) => PromoImages(
        craft: json?['craft'] as String?,
        discover: json?['discover'] as String?,
      );
}

class Programme {
  const Programme({
    required this.title,
    required this.description,
    required this.path,
    this.icon,
    this.external = false,
  });

  final String title;
  final String description;

  /// A path the app routes on, not a website URL.
  final String path;
  final String? icon;
  final bool external;

  factory Programme.fromJson(Map<String, dynamic> json) => Programme(
        title: (json['title'] ?? '') as String,
        description: (json['description'] ?? '') as String,
        path: (json['path'] ?? '') as String,
        icon: json['icon'] as String?,
        external: (json['external'] ?? false) as bool,
      );
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

class HomePayload {
  const HomePayload({
    this.banners = const [],
    this.postCategories = const [],
    this.stats = const [],
    this.testimonials = const [],
    this.ctaImage,
    this.promoImages = const PromoImages(),
    this.featuredStories = const [],
    this.featuredCraftsmen = const [],
    this.activeCampaigns = const [],
    this.programmes = const [],
    this.categorySections = const [],
    this.footerBanner,
  });

  final List<BannerSlide> banners;

  /// The subjects a reader browses by, under the hero.
  final List<PostCategoryTile> postCategories;

  /// The counted figures and the quote that share one band with the donate ask.
  final List<ImpactStat> stats;
  final List<Testimonial> testimonials;

  /// The photograph behind that band. Null and it draws a navy field.
  final String? ctaImage;

  final PromoImages promoImages;

  final List<PostSummary> featuredStories;
  final List<BusinessSummary> featuredCraftsmen;
  final List<Campaign> activeCampaigns;
  final List<Programme> programmes;

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
      postCategories: list('post_categories', PostCategoryTile.fromJson),
      stats: list('stats', ImpactStat.fromJson),
      testimonials: list('testimonials', Testimonial.fromJson),
      ctaImage: json['cta_image'] as String?,
      promoImages: PromoImages.fromJson(json['promo_images'] as Map<String, dynamic>?),
      featuredStories: list('featured_stories', PostSummary.fromJson),
      featuredCraftsmen: list('featured_craftsmen', BusinessSummary.fromJson),
      activeCampaigns: list('active_campaigns', Campaign.fromJson),
      programmes: list('programmes', Programme.fromJson),
      categorySections: list('category_sections', CategorySection.fromJson),
      footerBanner: footer == null ? null : BannerSlide.fromJson(footer),
    );
  }
}
