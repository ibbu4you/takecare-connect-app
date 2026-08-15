import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/post.dart';
import '../../core/router/route_names.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/html_body.dart';
import '../../core/widgets/pill.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/share_sheet.dart';
import '../../core/widgets/state_views.dart';

/// One story, read end to end.
class StoryScreen extends ConsumerWidget {
  const StoryScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final post = ref.watch(postProvider(slug));

    return Scaffold(
      appBar: AppBar(
        actions: [
          post.maybeWhen(
            data: (data) => ShareAction(path: '/blog/${data.slug}', title: data.title),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: post.when(
        loading: () => const LoadingView(height: 500),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(postProvider(slug)),
        ),
        data: (data) => _Article(post: data),
      ),
    );
  }
}

class _Article extends ConsumerWidget {
  const _Article({required this.post});

  final PostDetail post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // More from the same category. Read from the same paged provider the index
    // uses, so arriving here after browsing that category costs no request.
    final related = ref.watch(
      postsProvider((category: post.category?.slug, author: null, q: null)),
    );

    final more = related.items.where((p) => p.slug != post.slug).take(4).toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (post.image != null)
          AppImage(url: post.image, aspectRatio: 16 / 9, semanticLabel: post.title),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post.category != null)
                GestureDetector(
                  onTap: () => context.go('${Routes.stories}?category=${post.category!.slug}'),
                  child: Pill(post.category!.name),
                ),
              const SizedBox(height: 12),
              Text(post.title, style: AppText.h1),
              const SizedBox(height: 12),
              _Byline(post: post),
              const SizedBox(height: 16),
              if (post.excerpt.isNotEmpty) ...[
                Text(post.excerpt, style: AppText.lead.copyWith(color: AppColors.mutedForeground)),
                const SizedBox(height: 8),
                const Divider(height: 32),
              ],
              HtmlBody(post.body),
              const SizedBox(height: 24),
              ShareBar(path: '/blog/${post.slug}', title: post.title),
              if (post.author?.slug != null) ...[
                const SizedBox(height: 20),
                _AuthorBox(slug: post.author!.slug!),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
        if (more.isNotEmpty) ...[
          const SizedBox(height: 12),
          const SectionDivider(),
          SectionHeader(
            title: 'More like this',
            actionLabel: 'All',
            onAction: () => context.go(
              post.category == null
                  ? Routes.stories
                  : '${Routes.stories}?category=${post.category!.slug}',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (final other in more) ...[
                  PostCard(
                    post: other,
                    // replace, not push: otherwise reading four related stories
                    // in a row leaves four screens on the stack and the back
                    // button walks the reader backwards through all of them.
                    onTap: () => context.replace(Routes.story(other.slug)),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],

        // Whatever the team has carried across the blog. The website prints
        // this beside every article; the slugs already shown above are filtered
        // out here rather than server-side, because the server honours an
        // editor's choice as made and only its recency fallback excludes.
        _Trending(
          exclude: post.slug,
          alreadyShown: more.map((p) => p.slug).toSet(),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

/// The trending rail, as the website prints it beside every article.
///
/// Editor-curated through `is_trending`/`trending_order`, with recency as the
/// fallback so the section can never be empty because nobody made a choice —
/// nothing on this site counts views, so "latest" is the honest stand-in for
/// "trending" rather than a pretence of measurement.
///
/// Horizontal, unlike the web's sidebar column: a phone has no sidebar, and
/// stacking six more cards under "More like this" would turn the foot of every
/// article into a wall of nine.
class _Trending extends ConsumerWidget {
  const _Trending({required this.exclude, required this.alreadyShown});

  final String exclude;

  /// Slugs printed further up the page, filtered here so the reader is not
  /// shown the same card twice.
  final Set<String> alreadyShown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(trendingProvider(exclude)).valueOrNull ?? const [];
    final visible = posts.where((p) => !alreadyShown.contains(p.slug)).toList();

    if (visible.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const SectionDivider(),
        const SectionHeader(eyebrow: 'Doing the rounds', title: 'Trending stories'),
        SizedBox(
          height: 288,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: visible.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => PostTile(
              post: visible[i],
              onTap: () => context.replace(Routes.story(visible[i].slug)),
            ),
          ),
        ),
      ],
    );
  }
}

/// "About the author", under the article — the box the website closes every
/// story with.
///
/// Watches the author provider rather than using the byline already in hand,
/// because the post carries only a name and a slug; the bio and the avatar are
/// a separate fetch. It renders nothing at all until that arrives and nothing
/// ever if the author has written no bio, so a thin profile costs the reader a
/// blank card rather than showing one.
class _AuthorBox extends ConsumerWidget {
  const _AuthorBox({required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final author = ref.watch(authorProvider(slug)).valueOrNull;

    if (author == null || (author.bio?.trim().isEmpty ?? true)) {
      return const SizedBox.shrink();
    }

    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.push(Routes.author(slug)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: SizedBox(
              height: 44,
              width: 44,
              child: author.avatar == null
                  ? Container(
                      color: AppColors.surface,
                      alignment: Alignment.center,
                      child: Text(
                        author.name.trim().isEmpty
                            ? '?'
                            : author.name.trim()[0].toUpperCase(),
                        style: AppText.h3.copyWith(color: AppColors.primary),
                      ),
                    )
                  : AppImage(url: author.avatar, semanticLabel: author.name),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About ${author.name}', style: AppText.title.copyWith(fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  author.bio!,
                  style: AppText.excerpt,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  author.postCount == 1
                      ? 'Read their 1 story'
                      : 'Read all ${author.postCount} stories',
                  style: AppText.metaStrong.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Byline extends StatelessWidget {
  const _Byline({required this.post});

  final PostDetail post;

  @override
  Widget build(BuildContext context) {
    final author = post.author;

    return Row(
      children: [
        if (author != null) ...[
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.surface,
            child: Text(
              author.name.trim().isEmpty ? '?' : author.name.trim()[0].toUpperCase(),
              style: AppText.metaStrong.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (author != null)
                GestureDetector(
                  onTap: author.slug == null
                      ? null
                      : () => context.push(Routes.author(author.slug!)),
                  child: Text(
                    author.name,
                    style: AppText.metaStrong.copyWith(
                      fontSize: 13,
                      color: author.slug == null ? AppColors.foreground : AppColors.primary,
                    ),
                  ),
                ),
              Text(
                [
                  Fmt.date(post.publishedAt),
                  Fmt.readingTime(post.readingMinutes),
                ].where((s) => s.isNotEmpty).join('  ·  '),
                style: AppText.meta,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
