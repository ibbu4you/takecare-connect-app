library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/home.dart';
import '../../../core/models/post.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/card_carousel.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/widgets/pill.dart';
import '../../../core/widgets/section_header.dart';

/// The stories, with a tab per subject.
///
/// This is one section and not two, which is how the website has it: "All"
/// shows the newest across everything, and each tab swaps the rail for that
/// subject's newest. An earlier reading of the payload drew the featured
/// stories *and* a rail per category — nine bands of stories on one screen,
/// most of them showing the same articles twice.
class StoriesBand extends StatefulWidget {
  const StoriesBand({super.key, required this.featured, required this.sections});

  final List<PostSummary> featured;
  final List<CategorySection> sections;

  @override
  State<StoriesBand> createState() => _StoriesBandState();
}

class _StoriesBandState extends State<StoriesBand> {
  /// Null is "All".
  String? _slug;

  List<PostSummary> get _showing {
    if (_slug == null) return widget.featured;

    for (final section in widget.sections) {
      if (section.slug == _slug) return section.posts;
    }

    return widget.featured;
  }

  @override
  Widget build(BuildContext context) {
    final posts = _showing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The website's words: the stories are the Influencing Narratives
        // pillar, and the heading says what they are for.
        SectionHeader(
          eyebrow: 'Influencing Narratives',
          title: 'Stories that deserve to be seen',
          description: 'Discover the people, skills, ideas and communities behind the work.',
          actionLabel: 'View all',
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          onAction: () => context.go(
            _slug == null ? Routes.stories : '${Routes.stories}?category=$_slug',
          ),
        ),
        if (widget.sections.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: FilterPills(
              options: [
                for (final section in widget.sections)
                  (value: section.slug, label: section.name),
              ],
              selected: _slug,
              onSelected: (value) => setState(() => _slug = value),
              allLabel: 'All',
            ),
          ),

        if (posts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Nothing here yet.', style: AppText.meta),
          )
        else
          /*
           | One card at a time, snapping, with a sliver of the next showing.
           |
           | This was a full-width lead card above a strip of smaller ones — the
           | website's mosaic, squeezed. On a phone the two sizes read as two
           | different things rather than one row, and the strip stopped
           | wherever a thumb left it. Every story is now the same card and the
           | dots say how many there are.
           */
          CardCarousel(
            height: 344,
            itemCount: posts.length,
            itemBuilder: (context, i) => PostCard(
              expand: true,
              post: posts[i],
              onTap: () => context.go(Routes.story(posts[i].slug)),
            ),
          ),
      ],
    );
  }
}
