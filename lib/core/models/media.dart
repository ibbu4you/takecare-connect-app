import 'business.dart' show Photo;

/// Photo galleries and press coverage.

class GallerySummary {
  const GallerySummary({
    required this.slug,
    required this.title,
    required this.excerpt,
    this.cover,
    this.location,
    this.dateLabel,
    this.photoCount = 0,
  });

  final String slug;
  final String title;
  final String excerpt;
  final String? cover;
  final String? location;
  final String? dateLabel;
  final int photoCount;

  factory GallerySummary.fromJson(Map<String, dynamic> json) => GallerySummary(
        slug: (json['slug'] ?? '') as String,
        title: (json['title'] ?? '') as String,
        excerpt: (json['excerpt'] ?? '') as String,
        cover: json['cover'] as String?,
        location: json['location'] as String?,
        dateLabel: json['date_label'] as String?,
        photoCount: (json['photo_count'] ?? 0) as int,
      );
}

class GalleryDetail {
  const GalleryDetail({
    required this.slug,
    required this.title,
    this.description,
    this.location,
    this.dateLabel,
    this.photos = const [],
  });

  final String slug;
  final String title;
  final String? description;
  final String? location;
  final String? dateLabel;
  final List<Photo> photos;

  factory GalleryDetail.fromJson(Map<String, dynamic> json) => GalleryDetail(
        slug: (json['slug'] ?? '') as String,
        title: (json['title'] ?? '') as String,
        description: json['description'] as String?,
        location: json['location'] as String?,
        dateLabel: json['date_label'] as String?,
        photos: ((json['photos'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(Photo.fromJson)
            .toList(),
      );
}

enum PressKind { photo, video, website }

PressKind pressKindFromString(String? value) => switch (value) {
      'photo' => PressKind.photo,
      'video' => PressKind.video,
      _ => PressKind.website,
    };

extension PressKindX on PressKind {
  String get label => switch (this) {
        PressKind.photo => 'Newspaper cuttings',
        PressKind.video => 'On television',
        PressKind.website => 'Online',
      };
}

class PressVideo {
  const PressVideo({required this.type, this.provider, this.src, this.watchUrl, this.poster});

  final String type;
  final String? provider;
  final String? src;
  final String? watchUrl;
  final String? poster;

  static PressVideo? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    return PressVideo(
      type: (json['type'] ?? 'embed') as String,
      provider: json['provider'] as String?,
      src: json['src'] as String?,
      watchUrl: json['watch_url'] as String?,
      poster: json['poster'] as String?,
    );
  }
}

class PressItem {
  const PressItem({
    required this.kind,
    required this.title,
    this.outlet,
    this.description,
    this.publishedOnLabel,
    this.linkUrl,
    this.image,
    this.fullImage,
    this.video,
  });

  final PressKind kind;
  final String title;
  final String? outlet;
  final String? description;
  final String? publishedOnLabel;
  final String? linkUrl;
  final String? image;
  final String? fullImage;
  final PressVideo? video;

  factory PressItem.fromJson(Map<String, dynamic> json) => PressItem(
        kind: pressKindFromString(json['kind'] as String?),
        title: (json['title'] ?? '') as String,
        outlet: json['outlet'] as String?,
        description: json['description'] as String?,
        publishedOnLabel: json['published_on_label'] as String?,
        linkUrl: json['link_url'] as String?,
        image: json['image'] as String?,
        fullImage: json['full_image'] as String?,
        video: PressVideo.fromJson(json['video'] as Map<String, dynamic>?),
      );
}

class PressSection {
  const PressSection({
    required this.kind,
    required this.label,
    this.description = '',
    this.items = const [],
  });

  final PressKind kind;
  final String label;
  final String description;
  final List<PressItem> items;

  factory PressSection.fromJson(Map<String, dynamic> json) => PressSection(
        kind: pressKindFromString(json['kind'] as String?),
        label: (json['label'] ?? '') as String,
        description: (json['description'] ?? '') as String,
        items: ((json['items'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(PressItem.fromJson)
            .toList(),
      );
}
