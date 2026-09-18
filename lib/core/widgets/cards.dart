import 'package:flutter/material.dart';

import '../models/business.dart';
import '../models/campaign.dart';
import '../models/media.dart';
import '../models/post.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';
import 'app_image.dart';
import 'pill.dart';
import 'progress_bar.dart';

/// The shell every card shares: white, 16px radius, a 1px border and no
/// shadow — the website carries elevation with borders, and a Material drop
/// shadow would read as a different product.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.clip = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        clipBehavior: clip ? Clip.antiAlias : Clip.none,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// A story in a vertical list: image on top, category pill, title, excerpt,
/// byline.
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, this.onTap, this.expand = false});

  final PostSummary post;
  final VoidCallback? onTap;

  /// Fill a fixed height rather than sizing to the content.
  ///
  /// A card in a list sizes to whatever it holds. The same card in a carousel
  /// is handed a height, and its text block has to take what is left after the
  /// photograph — otherwise a title one line longer than the height allows
  /// overflows, which Flutter paints as hazard stripes and carries on from.
  ///
  /// Keyed on its own flag rather than inferred: [CampaignCard] used to infer
  /// it from `width`, and putting that card in a carousel that sets the height
  /// but not the width turned the protection off exactly where it was needed.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppImage(url: post.thumbnail, aspectRatio: 16 / 9, semanticLabel: post.title),
          _Fit(
            expand: expand,
            child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (post.category != null) ...[
                  Pill(post.category!.name, dense: true),
                  const SizedBox(height: 8),
                ],
              // Flexible where the height is fixed, so the title and the
              // excerpt give way to each other rather than pushing the byline
              // out of the bottom of the card. `Expanded` hands this column
              // the space left after the photograph; it does not make what is
              // inside it any smaller, which is what overflowed at the largest
              // font.
                _Give(
                  expand,
                  child: Text(
                    post.title,
                    style: AppText.h3,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (post.excerpt.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _Give(
                    expand,
                    child: Text(
                      post.excerpt,
                      style: AppText.excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                _MetaLine(
                  parts: [
                    if (post.author != null) post.author!.name,
                    if (post.publishedAt != null) Fmt.shortDate(post.publishedAt),
                    Fmt.readingTime(post.readingMinutes),
                  ],
                ),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }
}

/// The compact horizontal variant used in the home carousels, where a full
/// card would only fit one and a half to a screen.
///
/// The text sits in an [Expanded], which is what makes a fixed-height rail
/// safe. A carousel has to give its children a height, and any card that
/// simply stacks an image on top of text will overflow the moment a title runs
/// one line longer than whoever picked the number expected — or the moment a
/// reader turns their font size up. Expanded hands the text whatever is left
/// after the image and lets it ellipsise inside that, so the card adapts
/// instead of striping.
class PostTile extends StatelessWidget {
  const PostTile({super.key, required this.post, this.onTap, this.width = 250});

  final PostSummary post;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppImage(url: post.thumbnail, aspectRatio: 16 / 10, semanticLabel: post.title),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        post.title,
                        style: AppText.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post.category?.name ?? Fmt.shortDate(post.publishedAt),
                      style: AppText.meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A craftsman in the directory, built as [PostCard] is.
///
/// It used to be a 118px landscape row — a small square photograph beside the
/// name — on the reasoning that a directory wants density and the trade and
/// city matter as much as the name.
///
/// That undersold the work. These are interviews with photographs taken in the
/// workshop, and at 108px wide a loom, a kiln and a tray of pottery are the
/// same brown smudge. A story and a profile are the same kind of thing here,
/// so they are now the same card: the photograph gets the full width, and the
/// trade, the maker and the town drop to the meta line under the excerpt.
class BusinessCard extends StatelessWidget {
  const BusinessCard({super.key, required this.business, this.onTap, this.expand = false});

  final BusinessSummary business;
  final VoidCallback? onTap;

  /// Fill a fixed height rather than sizing to the content.
  ///
  /// A card in a list sizes to whatever it holds. The same card in a carousel
  /// is handed a height, and its text block has to take what is left after the
  /// photograph — otherwise a title one line longer than the height allows
  /// overflows, which Flutter paints as hazard stripes and carries on from.
  ///
  /// Keyed on its own flag rather than inferred: [CampaignCard] used to infer
  /// it from `width`, and putting that card in a carousel that sets the height
  /// but not the width turned the protection off exactly where it was needed.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppImage(url: business.thumbnail, aspectRatio: 16 / 9, semanticLabel: business.name),
          _Fit(
            expand: expand,
            child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (business.category != null) ...[
                  Pill(business.category!.name, dense: true),
                  const SizedBox(height: 8),
                ],
              // Flexible where the height is fixed, so the title and the
              // excerpt give way to each other rather than pushing the byline
              // out of the bottom of the card. `Expanded` hands this column
              // the space left after the photograph; it does not make what is
              // inside it any smaller, which is what overflowed at the largest
              // font.
                _Give(
                  expand,
                  child: Text(
                    business.name,
                    style: AppText.h3,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (business.excerpt.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _Give(
                    expand,
                    child: Text(
                      business.excerpt,
                      style: AppText.excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                // The maker, the town and the date, where a story puts its
                // author, its date and its reading time. A profile has no
                // reading time, and the town is the fact a reader wants in its
                // place.
                _MetaLine(
                  parts: [
                    if (business.ownerName != null) business.ownerName!,
                    if (business.city != null) business.city!.name,
                    if (business.publishedAt != null) Fmt.shortDate(business.publishedAt),
                  ],
                ),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }
}

/// The square variant for the home screen's craftsmen strip.
class BusinessTile extends StatelessWidget {
  const BusinessTile({super.key, required this.business, this.onTap, this.width = 165});

  final BusinessSummary business;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppImage(url: business.thumbnail, aspectRatio: 1, semanticLabel: business.name),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        business.name,
                        style: AppText.bodyStrong.copyWith(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      business.city?.name ?? business.category?.name ?? '',
                      style: AppText.meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A campaign, with its progress bar. The one card that spends accent red.
class CampaignCard extends StatelessWidget {
  const CampaignCard({
    super.key,
    required this.campaign,
    this.onTap,
    this.width,
    this.expand = false,
  });

  final Campaign campaign;
  final VoidCallback? onTap;

  /// Set where the card sits in a fixed-width rail; null makes it fill the
  /// column it is in.
  final double? width;

  /// Fill a fixed height rather than sizing to the content.
  ///
  /// A card in a list sizes to whatever it holds. The same card in a carousel
  /// is handed a height, and its text block has to take what is left after the
  /// photograph — otherwise a title one line longer than the height allows
  /// overflows, which Flutter paints as hazard stripes and carries on from.
  ///
  /// Keyed on its own flag rather than inferred: [CampaignCard] used to infer
  /// it from `width`, and putting that card in a carousel that sets the height
  /// but not the width turned the protection off exactly where it was needed.
  final bool expand;


  @override
  Widget build(BuildContext context) {
    final card = AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AppImage(url: campaign.image, aspectRatio: 16 / 9, semanticLabel: campaign.title),
              if (!campaign.isOpen)
                const Positioned(
                  top: 10,
                  left: 10,
                  child: Pill(
                    'Closed',
                    dense: true,
                    background: AppColors.footer,
                    foreground: AppColors.footerForeground,
                  ),
                ),
            ],
          ),
          // In a carousel the text is Expanded so it fits whatever height it
          // is given; in a column it sizes to its content.
          _Fit(
            expand: expand || width != null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      campaign.title,
                      style: AppText.h3,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (campaign.excerpt.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Flexible(
                      child: Text(
                        campaign.excerpt,
                        style: AppText.excerpt,
                        // One line where the height is fixed, two in a
                        // full-width card: the progress bar below is the part a
                        // donor actually needs to see.
                        maxLines: (expand || width != null) ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  CampaignProgress(campaign: campaign, compact: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return width == null ? card : SizedBox(width: width, child: card);
  }
}

/// Lets a child give way, but only where there is a fixed height to fit into.
///
/// In a list the card sizes to its content and nothing should shrink; in a
/// carousel the height is fixed and the longest title has to ellipsise rather
/// than push the byline off the bottom.
class _Give extends StatelessWidget {
  const _Give(this.flexible, {required this.child});

  final bool flexible;
  final Widget child;

  @override
  Widget build(BuildContext context) => flexible ? Flexible(child: child) : child;
}

/// Wraps a child in [Expanded] only when the parent has a bounded height.
class _Fit extends StatelessWidget {
  const _Fit({required this.expand, required this.child});

  final bool expand;
  final Widget child;

  @override
  Widget build(BuildContext context) => expand ? Expanded(child: child) : child;
}

/// A photo gallery, with its photograph count over the cover.
class GalleryCard extends StatelessWidget {
  const GalleryCard({super.key, required this.gallery, this.onTap});

  final GallerySummary gallery;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AppImage(url: gallery.cover, aspectRatio: 4 / 3, semanticLabel: gallery.title),
              if (gallery.photoCount > 0)
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Pill(
                    '${gallery.photoCount}',
                    icon: Icons.photo_library_outlined,
                    dense: true,
                    background: const Color(0xCC121A2B),
                    foreground: AppColors.footerForeground,
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gallery.title,
                  style: AppText.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _MetaLine(
                  parts: [
                    if (gallery.location != null && gallery.location!.isNotEmpty)
                      gallery.location!,
                    if (gallery.dateLabel != null && gallery.dateLabel!.isNotEmpty)
                      gallery.dateLabel!,
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Byline · date · reading time, joined with middots and never overflowing.
class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.parts});

  final List<String> parts;

  @override
  Widget build(BuildContext context) {
    final visible = parts.where((p) => p.trim().isNotEmpty).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Text(
      visible.join('  ·  '),
      style: AppText.meta,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
