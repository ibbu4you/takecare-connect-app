import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../router/route_names.dart';
import '../state/providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_image.dart';
import 'cards.dart';

/// "About the author", under the article — the box the website closes every
/// story with.
///
/// Watches the author provider rather than using the byline already in hand,
/// because the post carries only a name and a slug; the bio and the avatar are
/// a separate fetch. It renders nothing at all until that arrives and nothing
/// ever if the author has written no bio, so a thin profile costs the reader a
/// blank card rather than showing one.
class AuthorBox extends ConsumerWidget {
  const AuthorBox({super.key, required this.slug});

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
