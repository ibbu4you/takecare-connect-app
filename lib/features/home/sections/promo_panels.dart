library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/home.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_image.dart';

/// The two invitations: buy something, or tell us about your own work.
///
/// Matched in weight on purpose. The website's own redesign note says why: one
/// of them drawn larger reads as the site's main business, and for a foundation
/// whose purpose is the makers, neither of these is more important than the
/// other.
///
/// Either photograph may be absent, and the panel draws a flat field in its
/// place rather than a broken frame.
class PromoPanels extends StatelessWidget {
  const PromoPanels({super.key, required this.images});

  final PromoImages images;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // The website's own words, not a paraphrase. Somebody who reads the
          // site and then opens the app should meet the same two invitations.
          _Panel(
            image: images.craft,
            eyebrow: 'CRAFTSMEN & CREATORS',
            title: 'India’s craftsmen. Told properly.',
            body: 'From handloom and blue pottery to workshops making things nobody '
                'mass-produces. We visit, we photograph, and we print the number that '
                'reaches them.',
            actionLabel: 'Explore craft stories',
            onTap: () => context.go(Routes.craftsmen),
          ),
          const SizedBox(height: 12),
          _Panel(
            image: images.discover,
            eyebrow: 'GET DISCOVERED',
            title: 'Do you run a business worth knowing about?',
            body: 'Tell us what you make. If it fits the programme we come to you, '
                'photograph the work in progress, and publish the story — free, and '
                'only once you have read it.',
            actionLabel: 'Share your story',
            onTap: () => context.push(Routes.registerInterview),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.image,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onTap,
  });

  final String? image;
  final String eyebrow;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(AppRadii.card),
      clipBehavior: Clip.antiAlias,
      color: AppColors.footer,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            if (image != null && image!.isNotEmpty)
              Positioned.fill(child: AppImage(url: image, fit: BoxFit.cover)),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: image == null || image!.isEmpty
                        ? const [Color(0xFF121A2B), Color(0xFF1E2C6B)]
                        : const [Color(0xF00B1020), Color(0x990B1020)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(eyebrow, style: AppText.eyebrow),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: AppText.h3.copyWith(color: Colors.white, fontSize: 19),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: AppText.excerpt.copyWith(color: AppColors.footerMuted),
                  ),
                  const SizedBox(height: 14),
                  // Flexible, because "Register for an interview" beside an
                  // arrow is wider than the panel at a large font — and a Row
                  // whose text cannot shrink overflows by however much it
                  // needs, which Flutter paints as hazard stripes and carries
                  // on from. Nothing fails and nothing logs.
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          actionLabel,
                          style: AppText.button.copyWith(color: Colors.white, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                    ],
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
