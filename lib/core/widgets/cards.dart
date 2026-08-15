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
  const PostCard({super.key, required this.post, this.onTap});

  final PostSummary post;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppImage(url: post.thumbnail, aspectRatio: 16 / 9, semanticLabel: post.title),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.category != null) ...[
                  Pill(post.category!.name, dense: true),
                  const SizedBox(height: 8),
                ],
                Text(post.title, style: AppText.h3, maxLines: 3, overflow: TextOverflow.ellipsis),
                if (post.excerpt.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    post.excerpt,
                    style: AppText.excerpt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

/// A craftsman in the directory.
///
/// Landscape rather than portrait: the photographs are of workshops and hands
/// at work, and the trade and city matter as much as the name — a row gives
/// all three at a glance and fits four to a screen instead of one and a half.
class BusinessCard extends StatelessWidget {
  const BusinessCard({super.key, required this.business, this.onTap});

  final BusinessSummary business;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      // A fixed row height, so the photograph fills its side of the card.
      //
      // The obvious version — `CrossAxisAlignment.stretch` and let the text
      // decide the height — throws: a Row in a ListView has unbounded height,
      // and stretching hands the image an infinite height constraint, which
      // takes the whole directory down to a blank screen with nothing in
      // `flutter analyze` about it. Bounding the row first makes stretch legal
      // and gives the list an even rhythm, which is what a directory wants
      // anyway.
      child: SizedBox(
        height: 118,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 108,
              child: AppImage(url: business.thumbnail, semanticLabel: business.name),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        business.name,
                        style: AppText.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (business.ownerName != null && business.ownerName!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        business.ownerName!,
                        style: AppText.meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    // One row of pills, clipped rather than wrapped: the card
                    // has a fixed height and a second run would push the name
                    // out of it.
                    Row(
                      children: [
                        if (business.category != null)
                          Flexible(child: Pill(business.category!.name, dense: true)),
                        if (business.category != null && business.city != null)
                          const SizedBox(width: 6),
                        if (business.city != null)
                          Flexible(
                            child: Pill(
                              business.city!.name,
                              icon: Icons.place_outlined,
                              dense: true,
                              background: AppColors.surface,
                              foreground: AppColors.mutedForeground,
                            ),
                          ),
                      ],
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
  const CampaignCard({super.key, required this.campaign, this.onTap, this.width});

  final Campaign campaign;
  final VoidCallback? onTap;

  /// Set on the home carousel; null makes it fill the column.
  final double? width;

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
          // In the rail the text is Expanded so it fits whatever height the
          // carousel gives it; in a column it sizes to its content.
          _Fit(
            expand: width != null,
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
                        // One line in the rail, two in a full-width card: the
                        // rail's height is fixed and the progress bar below is
                        // the part a donor actually needs to see.
                        maxLines: width == null ? 2 : 1,
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
