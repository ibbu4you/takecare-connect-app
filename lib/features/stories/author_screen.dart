import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/post.dart';
import '../../core/router/route_names.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/paged_list_view.dart';
import '../../core/widgets/state_views.dart';

/// A writer's profile and everything they have written.
///
/// The posts are not part of the `/authors/{slug}` payload — they are a
/// cursor-paginated list like every other, fetched from `/posts?author=`. The
/// profile is the list's header, which is why this screen watches two
/// providers rather than one.
class AuthorScreen extends ConsumerWidget {
  const AuthorScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authorProvider(slug));
    final query = (category: null, author: slug, q: null);
    final posts = ref.watch(postsProvider(query));

    return Scaffold(
      appBar: AppBar(title: Text(profile.valueOrNull?.name ?? 'Author')),
      body: profile.when(
        loading: () => const LoadingView(height: 400),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(authorProvider(slug)),
        ),
        data: (author) => PagedListView(
          state: posts,
          header: _Profile(author: author),
          onLoadMore: () => ref.read(postsProvider(query).notifier).loadMore(),
          onRefresh: () async {
            ref.invalidate(authorProvider(slug));
            await ref.read(postsProvider(query).notifier).refresh();
          },
          emptyView: const EmptyView(
            title: 'Nothing published yet',
            icon: Icons.article_outlined,
          ),
          itemBuilder: (context, post, _) => PostCard(
            post: post,
            onTap: () => context.push(Routes.story(post.slug)),
          ),
        ),
      ),
    );
  }
}

class _Profile extends StatelessWidget {
  const _Profile({required this.author});

  final AuthorProfile author;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipOval(
              child: SizedBox(
                height: 64,
                width: 64,
                child: author.avatar == null
                    ? Container(
                        color: AppColors.surface,
                        alignment: Alignment.center,
                        child: Text(
                          author.name.trim().isEmpty ? '?' : author.name.trim()[0].toUpperCase(),
                          style: AppText.h2.copyWith(color: AppColors.primary),
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
                  Text(author.name, style: AppText.h2.copyWith(fontSize: 20)),
                  const SizedBox(height: 2),
                  Text(
                    author.postCount == 1 ? '1 story' : '${author.postCount} stories',
                    style: AppText.meta,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (author.bio != null && author.bio!.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(author.bio!, style: AppText.body.copyWith(fontSize: 15)),
        ],
        const SizedBox(height: 18),
        const Divider(height: 1),
      ],
    );
  }
}
