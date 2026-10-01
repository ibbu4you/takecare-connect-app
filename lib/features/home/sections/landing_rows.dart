library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/home.dart';
import '../../../core/models/post.dart';
import '../../../core/models/shop.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ai_note.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/section_header.dart';

/*
 | The website's swipe rows and the cards in them, as the website draws them
 | on a phone — CardCarousel, FeatureCard and ProductCard in its
 | resources/js/Components.
 */

/// The website's CardCarousel, on a phone.
///
/// One card at a time across the full width, not a peek of the next one;
/// "View all" and the previous and next arrows on their own row under the
/// heading, the arrows greying out at either end rather than wrapping; no dots.
/// It moves on by itself every five seconds and stops for good as soon as the
/// reader swipes or presses an arrow.
class LandingCarousel extends StatefulWidget {
  const LandingCarousel({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.viewAllLabel,
    required this.onViewAll,
    required this.itemCount,
    required this.itemBuilder,
    required this.height,
    this.description,
    this.filters,
    this.onDark = false,
  });

  final String eyebrow;
  final String title;
  final String? description;
  final String viewAllLabel;
  final VoidCallback onViewAll;

  /// The filter pills, on their own row under the arrows.
  final Widget? filters;

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// Every card in a row is the same height, as on the website.
  final double height;

  /// White words and outlined arrows, for a navy section.
  final bool onDark;

  @override
  State<LandingCarousel> createState() => _LandingCarouselState();
}

class _LandingCarouselState extends State<LandingCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();

    if (widget.itemCount > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted || !_controller.hasClients) return;
        _animateTo(_index + 1 < widget.itemCount ? _index + 1 : 0);
      });
    }
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _animateTo(int page) => _controller.animateToPage(
        page,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );

  @override
  void dispose() {
    _stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final linkColour = widget.onDark ? AppColors.primaryForeground : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          eyebrow: widget.eyebrow,
          title: widget.title,
          description: widget.description,
          onDark: widget.onDark,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Flexible(
                child: InkWell(
                  onTap: widget.onViewAll,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            widget.viewAllLabel,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.bodyStrong.copyWith(fontSize: 14, color: linkColour),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, size: 16, color: linkColour),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (widget.itemCount > 1) ...[
                _Arrow(
                  icon: Icons.chevron_left_rounded,
                  label: 'Previous',
                  onDark: widget.onDark,
                  onTap: _index == 0
                      ? null
                      : () {
                          _stop();
                          _animateTo(_index - 1);
                        },
                ),
                const SizedBox(width: 8),
                _Arrow(
                  icon: Icons.chevron_right_rounded,
                  label: 'Next',
                  onDark: widget.onDark,
                  onTap: _index >= widget.itemCount - 1
                      ? null
                      : () {
                          _stop();
                          _animateTo(_index + 1);
                        },
                ),
              ],
            ],
          ),
        ),
        if (widget.filters != null)
          Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: widget.filters),
        const SizedBox(height: 18),
        SizedBox(
          height: widget.height,
          child: NotificationListener<ScrollStartNotification>(
            onNotification: (notification) {
              if (notification.dragDetails != null) _stop();

              return false;
            },
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.itemCount,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: widget.itemBuilder(context, i),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.label, required this.onDark, this.onTap});

  final IconData icon;
  final String label;
  final bool onDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: Material(
          color: onDark ? Colors.transparent : AppColors.card,
          shape: CircleBorder(
            side: BorderSide(
              color: onDark ? AppColors.primaryForeground.withValues(alpha: 0.4) : AppColors.border,
            ),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(
                icon,
                size: 18,
                color: onDark ? AppColors.primaryForeground : AppColors.mutedForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================== stories ===

/// "Stories that deserve to be seen", with a pill per series.
///
/// "All" shows the featured stories; a pill shows that series' newest, and the
/// row starts again from its first card. The pills wrap onto as many lines as
/// they need, as the website's do, rather than scrolling sideways.
class LandingStoriesBand extends StatefulWidget {
  const LandingStoriesBand({super.key, required this.featured, required this.sections});

  final List<PostSummary> featured;
  final List<CategorySection> sections;

  @override
  State<LandingStoriesBand> createState() => _LandingStoriesBandState();
}

class _LandingStoriesBandState extends State<LandingStoriesBand> {
  /// Null is "All".
  String? _slug;

  @override
  Widget build(BuildContext context) {
    final section = widget.sections.where((s) => s.slug == _slug).firstOrNull;
    final posts = section?.posts ?? widget.featured;

    return LandingCarousel(
      // A new row for each pill, so it starts from its first card.
      key: ValueKey(_slug ?? 'all'),
      eyebrow: 'Influencing Narratives',
      title: 'Stories that deserve to be seen',
      description: 'Discover the people, skills, ideas and communities behind the work.',
      viewAllLabel: 'View all',
      onViewAll: () => context.go(
        section == null ? Routes.stories : '${Routes.stories}?category=${section.slug}',
      ),
      filters: widget.sections.isEmpty
          ? null
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Pill(
                    label: 'All', active: _slug == null, onTap: () => setState(() => _slug = null)),
                for (final candidate in widget.sections)
                  _Pill(
                    label: candidate.name,
                    active: _slug == candidate.slug,
                    onTap: () => setState(() => _slug = candidate.slug),
                  ),
              ],
            ),
      itemCount: posts.length,
      height: 436,
      itemBuilder: (context, i) => StoryCard(
        post: posts[i],
        // Only on the first, and only on the curated list, as on the website:
        // a series' newest story is not something anybody "featured".
        featured: i == 0 && section == null,
        onTap: () => context.go(Routes.story(posts[i].slug)),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: active,
      button: true,
      child: Material(
        color: active ? AppColors.primary : AppColors.card,
        shape: StadiumBorder(
          side: BorderSide(color: active ? AppColors.primary : AppColors.border),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            child: Text(
              label,
              style: AppText.body.copyWith(
                fontSize: 14,
                height: 1.2,
                fontWeight: FontWeight.w500,
                color: active ? AppColors.primaryForeground : AppColors.foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The website's FeatureCard: the series and read time on the photograph, the
/// title and two lines of it, and the author with a round arrow at the foot.
class StoryCard extends StatelessWidget {
  const StoryCard({super.key, required this.post, required this.onTap, this.featured = false});

  final PostSummary post;
  final VoidCallback onTap;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final author = post.author?.name;

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadii.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AppImage(url: post.thumbnail, aspectRatio: 16 / 10, semanticLabel: post.title),
                  if (featured)
                    const Positioned(
                      left: 12,
                      top: 12,
                      child: _Badge(
                        background: AppColors.accent,
                        foreground: AppColors.accentForeground,
                        icon: Icons.auto_awesome,
                        label: 'Featured',
                      ),
                    ),
                  if (post.category != null)
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: _Badge(
                        background: Colors.white.withValues(alpha: 0.95),
                        foreground: AppColors.foreground,
                        label: post.category!.name,
                      ),
                    ),
                  if (post.readingMinutes > 0)
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: _Badge(
                        background: Colors.black.withValues(alpha: 0.55),
                        foreground: Colors.white,
                        label: '${post.readingMinutes} min read',
                        weight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyStrong.copyWith(height: 1.35),
                      ),
                      if (post.excerpt.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Flexible(
                          child: Text(
                            post.excerpt,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.excerpt.copyWith(fontSize: 14),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          if (author != null) ...[
                            _Initials(name: author),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (author != null)
                                  Text(
                                    author,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.bodyStrong.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                if (post.publishedAt != null)
                                  Text(
                                    Fmt.date(post.publishedAt),
                                    maxLines: 1,
                                    style: AppText.meta,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: AppColors.mutedForeground,
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
      ),
    );
  }
}

/// The author's initials in a pale navy disc, the website's avatar fallback.
class _Initials extends StatelessWidget {
  const _Initials({required this.name});

  final String name;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';

    return (parts.length == 1 ? parts.first[0] : parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Text(
          _initials,
          style: AppText.metaStrong.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.background,
    required this.foreground,
    required this.label,
    this.icon,
    this.weight = FontWeight.w600,
  });

  final Color background;
  final Color foreground;
  final String label;
  final IconData? icon;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.meta.copyWith(fontSize: 11, fontWeight: weight, color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================= shop ===

/// The website's ProductCard: the category on the photograph, the name, who
/// made it and where, the price, and a full-width "View details" button.
///
/// No Buy button, here or anywhere: the foundation takes no part in the sale.
class LandingProductCard extends StatelessWidget {
  const LandingProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.fill = true,
  });

  final ShopProduct product;

  /// Fills the height it is given, with the price pinned to the foot so that
  /// prices line up across a carousel. Off in the shop's list, where each card
  /// is as tall as its own content.
  final bool fill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadii.field),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.field),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  if (product.thumbnail?.isNotEmpty ?? false)
                    AppImage(
                        url: product.thumbnail, aspectRatio: 4 / 3, semanticLabel: product.name)
                  else
                    // The website's words for a product still waiting on its
                    // photograph, rather than a broken-image glyph.
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: ColoredBox(
                        color: AppColors.surface,
                        child: Center(
                          child:
                              Text('No photograph yet', style: AppText.meta.copyWith(fontSize: 14)),
                        ),
                      ),
                    ),
                  if (product.category != null)
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 220),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sell_outlined, size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                product.category!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.meta.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.foreground,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (product.aiAssisted)
                    const Positioned(right: 8, bottom: 8, child: AiNote.badge()),
                ],
              ),
              _fillIf(
                fill,
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyStrong.copyWith(height: 1.35),
                      ),
                      if (product.maker != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'by ${product.maker!.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.meta.copyWith(fontSize: 14),
                        ),
                      ],
                      if (fill) const Spacer() else const SizedBox(height: 12),
                      Text(
                        product.priceLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyStrong.copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: onTap,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.primaryForeground,
                            minimumSize: const Size.fromHeight(38),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadii.small),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Flexible, so on a narrow phone at a large font
                              // the label gives way rather than the button
                              // painting past the card's edge.
                              Flexible(
                                child: Text(
                                  'View details',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.button.copyWith(fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _fillIf(bool fill, Widget child) => fill ? Expanded(child: child) : child;
