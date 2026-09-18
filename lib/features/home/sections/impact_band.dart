library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/home.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_image.dart';

/// The quote, the figures, and the invitation — one card.
///
/// Laid out as the website's band is, because it is the same argument: a
/// person saying it in their own words, the numbers behind it, and then the
/// thing a reader can do. They were two stacked sections with a seam of grey
/// between them before the site folded them together.
///
/// **The figures are counted, never typed.** They come from the server's own
/// `stats`, shared with the website, so the app cannot tell somebody the
/// foundation has published a different number of stories than the site does.
/// Only what the database actually knows is in there — readers, reach and
/// lives touched are real things nobody here can measure, and a charity
/// inventing them beside a Donate button is the one number nobody should
/// guess at.
///
/// The photograph behind it is sent by the API, which falls back to the one
/// shipped in the website's repository. It used to be null here and the band
/// drew a flat navy field where the website showed a handloom.
class ImpactBand extends StatelessWidget {
  const ImpactBand({
    super.key,
    required this.stats,
    required this.testimonials,
    this.image,
  });

  final List<ImpactStat> stats;
  final List<Testimonial> testimonials;
  final String? image;

  @override
  Widget build(BuildContext context) {
    final quote = testimonials.isEmpty ? null : testimonials.first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.card + 6),
        child: Stack(
          children: [
            /*
             | A navy duotone, not a fog.
             |
             | Multiplied into the photograph rather than laid over it. A plain
             | navy wash at three quarters — which is what this was — lifts the
             | shadows of a bright picture into a flat lavender haze and loses
             | the loom entirely; multiply keeps the dark parts dark and turns
             | the light parts navy, so the picture stays legible as a picture
             | and the card still reads as the foundation's colour.
             |
             | The legibility that costs is bought back where the words are
             | rather than by darkening everything: the figures sit on panels of
             | their own, and the invitation sits under a gradient that deepens
             | towards it.
             */
            Positioned.fill(
              child: image == null || image!.isEmpty
                  ? const ColoredBox(color: AppColors.primaryDark)
                  : ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF1E2C6B),
                        BlendMode.multiply,
                      ),
                      child: AppImage(url: image, fit: BoxFit.cover),
                    ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xD91E2C6B)],
                    stops: [0.35, 1],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 26, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (quote != null) ...[
                    _Quote(quote: quote),
                    const SizedBox(height: 22),
                    const _Rule(),
                    const SizedBox(height: 22),
                  ],

                  if (stats.isNotEmpty) ...[
                    _Figures(stats: stats),
                    const SizedBox(height: 22),
                    const _Rule(),
                    const SizedBox(height: 22),
                  ],

                  /*
                   | The invitation, never gated on the quote or the figures.
                   |
                   | This is the only route to volunteering anywhere on the
                   | home page, and both the quote and the stats can be empty —
                   | so hanging the ask off either would quietly take it away.
                   */
                  Text(
                    'Join a growing community',
                    style: AppText.h2.copyWith(color: Colors.white, fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Changemakers, creators and dreamers — and the people who back them.',
                    style: AppText.excerpt.copyWith(color: const Color(0xBFFFFFFF)),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context.push(Routes.volunteer),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentButton,
                        minimumSize: const Size(0, 50),
                      ),
                      label: const Text('Be part of it'),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      iconAlignment: IconAlignment.end,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The figures, two across.
///
/// A wrap rather than a grid, so a short last row sits where it falls instead
/// of leaving half a row of empty panel beside the fifth figure — which is
/// what a fixed grid does, and it reads as something that failed to load.
class _Figures extends StatelessWidget {
  const _Figures({required this.stats});

  final List<ImpactStat> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Two across, less the gutter between them.
        final width = (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            for (final stat in stats)
              SizedBox(
                width: width,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x8C1E2C6B),
                    borderRadius: BorderRadius.circular(AppRadii.tile),
                    border: Border.all(color: const Color(0x26FFFFFF)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Column(
                      children: [
                        Text(
                          stat.value,
                          style: AppText.figure.copyWith(color: Colors.white, fontSize: 26),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stat.label,
                          style: AppText.meta.copyWith(color: const Color(0xB3FFFFFF)),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Quote extends StatelessWidget {
  const _Quote({required this.quote});

  final Testimonial quote;

  @override
  Widget build(BuildContext context) {
    final attribution = [
      if (quote.authorName != null && quote.authorName!.isNotEmpty) quote.authorName!,
      if (quote.authorRole != null && quote.authorRole!.isNotEmpty) quote.authorRole!,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.format_quote_rounded, size: 30, color: Color(0x40FFFFFF)),
        const SizedBox(height: 6),
        Text(
          '“${quote.quote}”',
          style: AppText.lead.copyWith(color: Colors.white, height: 1.5),
        ),
        if (attribution.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              // Initials rather than a grey silhouette where there is no
              // photograph — the website's own choice, and it reads better.
              if (quote.avatar != null && quote.avatar!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ClipOval(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: AppImage(url: quote.avatar, semanticLabel: quote.authorName),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0x33FFFFFF),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _initials(quote.authorName),
                      style: AppText.metaStrong.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  attribution,
                  style: AppText.meta.copyWith(color: const Color(0xB3FFFFFF)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  static String _initials(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);

    if (parts.isEmpty) return '“';

    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: Color(0x26FFFFFF));
}
