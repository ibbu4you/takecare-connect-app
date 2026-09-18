library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/home.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_image.dart';

/// The figures, a quote, and the invitation to give — one band.
///
/// They were a stats strip and a separate donate call with a seam of grey
/// between them, making one argument in two places. The website folded them
/// together and so does this: the numbers are the evidence, the quote is a
/// person saying it in their own words, and the button is what the reader can
/// do about it.
///
/// **The figures are counted, never typed.** They come from the server's own
/// `stats`, shared with the website, so the app cannot tell somebody the
/// foundation has published a different number of stories than the site does.
/// Only what the database actually knows is there — readers, reach and lives
/// touched are real things nobody here can measure, and a charity inventing
/// them beside a Donate button is the one number nobody should guess at.
class ImpactBand extends StatelessWidget {
  const ImpactBand({
    super.key,
    required this.stats,
    required this.testimonials,
    this.image,
  });

  final List<ImpactStat> stats;
  final List<Testimonial> testimonials;

  /// The photograph behind the band. Null and it draws a navy field, which is
  /// what the website does.
  final String? image;

  @override
  Widget build(BuildContext context) {
    final quote = testimonials.isEmpty ? null : testimonials.first;

    return Stack(
      children: [
        Positioned.fill(
          child: image == null || image!.isEmpty
              ? const ColoredBox(color: AppColors.footer)
              : AppImage(url: image, fit: BoxFit.cover),
        ),
        // Heavy enough that white copy is legible over any photograph the
        // office uploads, since nobody can know in advance how bright it is.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xE60B1020), Color(0xF5121A2B)],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('WHAT WE HAVE DONE', style: AppText.eyebrow),
              const SizedBox(height: 8),
              Text(
                'Counted, not claimed',
                style: AppText.h2.copyWith(color: Colors.white),
              ),
              if (stats.isNotEmpty) ...[
                const SizedBox(height: 20),
                Wrap(
                  spacing: 28,
                  runSpacing: 18,
                  children: [for (final stat in stats) _Figure(stat: stat)],
                ),
              ],
              if (quote != null) ...[
                const SizedBox(height: 24),
                _Quote(quote: quote),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.go(Routes.donate),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentButton,
                    minimumSize: const Size(0, 48),
                  ),
                  icon: const Icon(Icons.favorite_rounded, size: 18),
                  label: const Text('Stand behind a maker'),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Every rupee is receipted and reported. 80G tax benefit applies.',
                style: AppText.meta.copyWith(color: AppColors.footerMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.stat});

  final ImpactStat stat;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          stat.value,
          style: AppText.figure.copyWith(color: Colors.white, fontSize: 24),
        ),
        const SizedBox(height: 2),
        Text(stat.label, style: AppText.meta.copyWith(color: AppColors.footerMuted)),
      ],
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
    ].join(', ');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: const Color(0x26FFFFFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '“${quote.quote}”',
              style: AppText.body.copyWith(color: Colors.white, fontSize: 15),
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
                          width: 34,
                          height: 34,
                          child: AppImage(
                            url: quote.avatar,
                            semanticLabel: quote.authorName,
                          ),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Container(
                        width: 34,
                        height: 34,
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
                      style: AppText.meta.copyWith(color: AppColors.footerMuted),
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _initials(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);

    if (parts.isEmpty) return '“';

    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}
