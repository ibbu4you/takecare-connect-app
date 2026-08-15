import 'business.dart';
import 'campaign.dart';
import 'post.dart';

/// Everything the Home tab draws, in one payload.
///
/// Composed server-side deliberately: a phone on a patchy connection should not
/// make six requests to fill one screen.

class BannerSlide {
  const BannerSlide({
    this.eyebrow,
    this.title,
    this.subtitle,
    this.image,
    this.mobileImage,
    this.isImageOnly = false,
    this.ctaLabel,
    this.ctaUrl,
  });

  final String? eyebrow;
  final String? title;
  final String? subtitle;
  final String? image;
  final String? mobileImage;

  /// A designed banner whose artwork carries its own words — no scrim, no
  /// overlaid copy.
  final bool isImageOnly;

  final String? ctaLabel;
  final String? ctaUrl;

  /// Prefer the portrait crop on a phone; the wide one is cropped to its
  /// middle otherwise, which cuts the words out of a designed banner.
  String? get bestImage => mobileImage ?? image;

  factory BannerSlide.fromJson(Map<String, dynamic> json) {
    final cta = json['cta'] as Map<String, dynamic>?;

    return BannerSlide(
      eyebrow: json['eyebrow'] as String?,
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      image: json['image'] as String?,
      mobileImage: json['mobile_image'] as String?,
      isImageOnly: (json['is_image_only'] ?? false) as bool,
      ctaLabel: cta?['label'] as String?,
      ctaUrl: cta?['url'] as String?,
    );
  }
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
    this.featuredStories = const [],
    this.featuredCraftsmen = const [],
    this.activeCampaigns = const [],
    this.programmes = const [],
    this.categorySections = const [],
  });

  final List<BannerSlide> banners;
  final List<PostSummary> featuredStories;
  final List<BusinessSummary> featuredCraftsmen;
  final List<Campaign> activeCampaigns;
  final List<Programme> programmes;
  final List<CategorySection> categorySections;

  factory HomePayload.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) =>
        ((json[key] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(parse)
            .toList();

    return HomePayload(
      banners: list('banners', BannerSlide.fromJson),
      featuredStories: list('featured_stories', PostSummary.fromJson),
      featuredCraftsmen: list('featured_craftsmen', BusinessSummary.fromJson),
      activeCampaigns: list('active_campaigns', Campaign.fromJson),
      programmes: list('programmes', Programme.fromJson),
      categorySections: list('category_sections', CategorySection.fromJson),
    );
  }
}
