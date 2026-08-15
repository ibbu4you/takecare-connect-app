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
        const SizedBox(height: 32),
      ],
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
