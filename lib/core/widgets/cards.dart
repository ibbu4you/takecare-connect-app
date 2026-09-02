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
  const BusinessCard({super.key, required this.business, this.onTap});

  final BusinessSummary business;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppImage(url: business.thumbnail, aspectRatio: 16 / 9, semanticLabel: business.name),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (business.category != null) ...[
                  Pill(business.category!.name, dense: true),
                  const SizedBox(height: 8),
                ],
                Text(business.name, style: AppText.h3, maxLines: 3, overflow: TextOverflow.ellipsis),
                if (business.excerpt.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    business.excerpt,
                    style: AppText.excerpt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
