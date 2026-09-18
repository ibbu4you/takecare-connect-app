library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/home.dart';
import '../../../core/models/post.dart';
import '../../../core/router/route_names.dart';
import '../../../core/router/web_paths.dart';
import '../../../core/theme/app_colors.dart';
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
        SectionHeader(
          eyebrow: 'From the field',
          title: 'Stories',
          actionLabel: 'All',
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

/// The four programmes, each with its own glyph.
///
/// The `icon` key has been in the payload all along and the app drew the same
/// hand-holding symbol for all four, which made them read as one repeated
/// thing rather than four different programmes.
class ProgrammesBand extends StatelessWidget {
  const ProgrammesBand({super.key, required this.programmes});

  final List<Programme> programmes;

  static const _icons = <String, IconData>{
    'craftsmen': Icons.handyman_outlined,
    'brands': Icons.storefront_outlined,
    'startups': Icons.rocket_launch_outlined,
    'humanity': Icons.emoji_events_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final programme in programmes) ...[
            AppCard(
              padding: const EdgeInsets.all(14),
              // Through the translator, never straight to `context.go`. These
              // paths are the website's — `/blog/category/tales-of-brands`,
              // `/interview-today` — and three of the four programme cards
              // landed on the "page has moved" screen when they were passed
              // through unchanged.
              onTap: programme.path.isEmpty
                  ? null
                  : () => openWebPath(context, programme.path),
              child: Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.small),
                    ),
                    child: Icon(
                      // A key the app does not recognise falls back rather
                      // than leaving a blank square.
                      _icons[programme.icon] ?? Icons.volunteer_activism_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(programme.title, style: AppText.title.copyWith(fontSize: 15)),
                        if (programme.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            programme.description,
                            style: AppText.meta,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (programme.path.isNotEmpty)
                    Icon(
                      // An external programme leaves the app; say so.
                      programme.external
                          ? Icons.open_in_new_rounded
                          : Icons.chevron_right_rounded,
                      size: programme.external ? 16 : 24,
                      color: AppColors.mutedForeground,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
