/// A story, in the two shapes the API returns it.
///
/// Every field has a defensive default. The API is stable, but a card that
/// renders "" is a card; a card that throws takes the whole list with it.
library;

class Taxonomy {
  const Taxonomy({required this.slug, required this.name});

  final String slug;
  final String name;

  static Taxonomy? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    return Taxonomy(
      slug: (json['slug'] ?? '') as String,
      name: (json['name'] ?? '') as String,
    );
  }
}

class AuthorRef {
  const AuthorRef({required this.name, this.slug});

  final String name;
  final String? slug;

  static AuthorRef? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    return AuthorRef(
      name: (json['name'] ?? '') as String,
      slug: json['slug'] as String?,
    );
  }
}

class PostSummary {
  const PostSummary({
    required this.slug,
    required this.title,
    required this.excerpt,
    this.thumbnail,
    this.category,
    this.author,
    this.readingMinutes = 1,
    this.publishedAt,
  });

  final String slug;
  final String title;
  final String excerpt;
  final String? thumbnail;
  final Taxonomy? category;
  final AuthorRef? author;
  final int readingMinutes;
  final DateTime? publishedAt;

  factory PostSummary.fromJson(Map<String, dynamic> json) => PostSummary(
        slug: (json['slug'] ?? '') as String,
        title: (json['title'] ?? '') as String,
        excerpt: (json['excerpt'] ?? '') as String,
        thumbnail: json['thumbnail'] as String?,
        category: Taxonomy.fromJson(json['category'] as Map<String, dynamic>?),
        author: AuthorRef.fromJson(json['author'] as Map<String, dynamic>?),
        readingMinutes: (json['reading_minutes'] ?? 1) as int,
        publishedAt: DateTime.tryParse((json['published_at'] ?? '') as String),
      );
}

class PostDetail {
  const PostDetail({
    required this.slug,
    required this.title,
    required this.excerpt,
    this.body,
    this.image,
    this.category,
    this.author,
    this.readingMinutes = 1,
    this.publishedAt,
  });

  final String slug;
  final String title;
  final String excerpt;

  /// Raw HTML, sanitised server-side on save. Rendered by HtmlBody.
  final String? body;
  final String? image;
  final Taxonomy? category;
  final AuthorRef? author;
  final int readingMinutes;
  final DateTime? publishedAt;

  factory PostDetail.fromJson(Map<String, dynamic> json) => PostDetail(
        slug: (json['slug'] ?? '') as String,
        title: (json['title'] ?? '') as String,
        excerpt: (json['excerpt'] ?? '') as String,
        body: json['body'] as String?,
        image: json['image'] as String?,
        category: Taxonomy.fromJson(json['category'] as Map<String, dynamic>?),
        author: AuthorRef.fromJson(json['author'] as Map<String, dynamic>?),
        readingMinutes: (json['reading_minutes'] ?? 1) as int,
        publishedAt: DateTime.tryParse((json['published_at'] ?? '') as String),
      );
}

class AuthorProfile {
  const AuthorProfile({
    required this.name,
    this.slug,
    this.bio,
    this.avatar,
    this.postCount = 0,
  });

  final String name;
  final String? slug;
  final String? bio;
  final String? avatar;
  final int postCount;

  factory AuthorProfile.fromJson(Map<String, dynamic> json) => AuthorProfile(
        name: (json['name'] ?? '') as String,
        slug: json['slug'] as String?,
        bio: json['bio'] as String?,
        avatar: json['avatar'] as String?,
        postCount: (json['post_count'] ?? 0) as int,
      );
}

/// A category or city, with how much sits under it.
class TaxonomyOption {
  const TaxonomyOption({
    required this.slug,
    required this.name,
    this.state,
    this.description,
    this.count = 0,
  });

  final String slug;
  final String name;
  final String? state;
  final String? description;
  final int count;

  factory TaxonomyOption.fromJson(Map<String, dynamic> json) => TaxonomyOption(
        slug: (json['slug'] ?? '') as String,
        name: (json['name'] ?? '') as String,
        state: json['state'] as String?,
        description: json['description'] as String?,
        count: (json['count'] ?? 0) as int,
      );
}
