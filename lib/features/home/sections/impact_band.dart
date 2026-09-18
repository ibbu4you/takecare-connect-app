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

/// The figures, two across and every tile exactly the same size.
///
/// Equal tiles are the whole point of this grid, and a [Wrap] could not give
/// them: it sizes each child to its own content, so "Subjects covered" on one
/// line sat beside "Businesses interviewed" on two and the row came out
/// ragged, with the panels visibly different heights.
///
/// The fix is to reserve two lines for every label whether it uses them or
/// not. Every tile is then identical by construction — one line of figure, two
/// of label, the same padding — with nothing to measure, nothing to fall out
/// of step at a larger font, and no dependency on how long any particular
/// label happens to be.
///
/// An odd last figure spans the full width rather than sitting alone in a
/// half-width tile with a hole beside it. The website fits all five in a
/// single row; on a phone, the closing figure reading right across the foot of
/// the grid is the nearest honest translation of that, and it is the one
/// arrangement that leaves no gap.
class _Figures extends StatelessWidget {
  const _Figures({required this.stats});

  final List<ImpactStat> stats;

  /// Set on the label *and* used to reserve its box. If these two ever
  /// disagree the text overflows the space kept for it, so they are one
  /// constant rather than two numbers that happen to match today.
  static const _labelLeading = 1.3;

  static const _gutter = 10.0;

  @override
  Widget build(BuildContext context) {
    // Scaled here rather than left to the Text, because the reserved height
    // has to grow with the user's font setting by exactly as much as the words
    // inside it do.
    final labelHeight =
        MediaQuery.textScalerOf(context).scale(AppText.meta.fontSize ?? 12) * _labelLeading * 2;

    final rows = <Widget>[];

    for (var start = 0; start < stats.length; start += 2) {
      if (rows.isNotEmpty) {
        rows.add(const SizedBox(height: _gutter));
      }

      rows.add(
        // No CrossAxisAlignment.stretch: this sits in a column with no height
        // of its own, so stretch would be asked to fill an infinite one and
        // assert. The tiles are the same height anyway, by construction.
        Row(
          children: [
            for (var i = start; i < start + 2 && i < stats.length; i++) ...[
              if (i > start) const SizedBox(width: _gutter),
              Expanded(child: _Figure(stat: stats[i], labelHeight: labelHeight)),
            ],
          ],
        ),
      );
    }

    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}

/// One panel: the number, and what it counts.
class _Figure extends StatelessWidget {
  const _Figure({required this.stat, required this.labelHeight});

  final ImpactStat stat;

  /// Two lines' worth, passed in so every tile in the grid agrees on it.
  final double labelHeight;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x8C1E2C6B),
        borderRadius: BorderRadius.circular(AppRadii.tile),
        border: Border.all(color: const Color(0x26FFFFFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              stat.value,
              style: AppText.figure.copyWith(color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: labelHeight,
              // Full width, so a one-word label is centred in the panel rather
              // than sized to the word — the panels are meant to read as a
              // grid of equal cells, not as text that happens to be boxed.
              width: double.infinity,
              child: Text(
                stat.label,
                style: AppText.meta.copyWith(
                  color: const Color(0xB3FFFFFF),
                  height: _Figures._labelLeading,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
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
