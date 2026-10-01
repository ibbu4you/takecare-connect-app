library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/models/home.dart';
import '../../../core/router/web_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_image.dart';

/// The hero, as the website's HeroSlider draws it on a phone.
///
/// A tall navy-washed slide with the words in the middle — a red eyebrow, the
/// title, the line under it, and two full-width buttons, red and outlined —
/// and along the bottom the website's controls: previous, next and pause as
/// three round buttons, then a bar per slide, the current one long and red.
///
/// It moves on by itself every six seconds, stops for good once the reader
/// swipes or presses anything, and pauses while they hold the pause button —
/// the website's rules.
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key, required this.banners});

  final List<BannerSlide> banners;

  /// An eyebrow, a two-line title, two lines under it and two buttons above
  /// the controls. Close to the website's own minimum on a phone (26rem, 416px);
  /// it was 540 and took most of the first screen.
  static const height = 440.0;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;
  bool _paused = false;

  bool get _isCarousel => widget.banners.length > 1;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    if (!_isCarousel) return;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) => _go(_index + 1));
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _go(int index) {
    if (!mounted || !_controller.hasClients) return;

    final count = widget.banners.length;
    _controller.animateToPage(
      ((index % count) + count) % count,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: BannerCarousel.height,
      child: ColoredBox(
        color: AppColors.primary,
        child: Stack(
          children: [
            NotificationListener<ScrollStartNotification>(
              onNotification: (notification) {
                // A swipe by the reader, not the timer's own animation.
                if (notification.dragDetails != null) {
                  _stop();
                  setState(() => _paused = true);
                }

                return false;
              },
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.banners.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => BannerFrame(slide: widget.banners[i]),
              ),
            ),
            if (_isCarousel)
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: Row(
                  children: [
                    _ControlButton(
                      icon: Icons.chevron_left_rounded,
                      label: 'Previous slide',
                      onTap: () => _go(_index - 1),
                    ),
                    const SizedBox(width: 8),
                    _ControlButton(
                      icon: Icons.chevron_right_rounded,
                      label: 'Next slide',
                      onTap: () => _go(_index + 1),
                    ),
                    const SizedBox(width: 8),
                    _ControlButton(
                      icon: _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      label: _paused ? 'Resume automatic slides' : 'Pause automatic slides',
                      onTap: () {
                        setState(() => _paused = !_paused);
                        _paused ? _stop() : _start();
                      },
                    ),
                    const SizedBox(width: 12),
                    for (var i = 0; i < widget.banners.length; i++)
                      GestureDetector(
                        onTap: () => _go(i),
                        child: Semantics(
                          button: true,
                          label: 'Go to slide ${i + 1}',
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(right: 8),
                            height: 6,
                            width: i == _index ? 32 : 12,
                            decoration: BoxDecoration(
                              color: i == _index
                                  ? AppColors.accent
                                  : AppColors.primaryForeground.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(AppRadii.pill),
                            ),
                          ),
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

/// One of the three round buttons: white ring, a little navy behind it.
class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppColors.primary.withValues(alpha: 0.4),
        shape: CircleBorder(
          side: BorderSide(color: AppColors.primaryForeground.withValues(alpha: 0.3)),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 18, color: AppColors.primaryForeground),
          ),
        ),
      ),
    );
  }
}

/// One slide.
class BannerFrame extends StatelessWidget {
  const BannerFrame({super.key, required this.slide});

  final BannerSlide slide;

  /// The website's wash: navy from the left, heaviest behind the words and
  /// clearing towards the right, at the strength the office chose.
  List<Color>? get _scrim => switch (slide.overlay) {
        BannerOverlay.none => null,
        BannerOverlay.light => [
            AppColors.primary.withValues(alpha: 0.7),
            AppColors.primary.withValues(alpha: 0.45),
            AppColors.primary.withValues(alpha: 0.1),
          ],
        BannerOverlay.standard => [
            AppColors.primary.withValues(alpha: 0.95),
            AppColors.primary.withValues(alpha: 0.8),
            AppColors.primary.withValues(alpha: 0.4),
          ],
        BannerOverlay.heavy => [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.9),
            AppColors.primary.withValues(alpha: 0.65),
          ],
      };

  @override
  Widget build(BuildContext context) {
    final scrim = _scrim;
    final hasTitle = slide.title?.isNotEmpty ?? false;
    final hasSubtitle = slide.subtitle?.isNotEmpty ?? false;
    final hasEyebrow = slide.eyebrow?.isNotEmpty ?? false;

    return Stack(
      fit: StackFit.expand,
      children: [
        AppImage(url: slide.bestImage, fit: BoxFit.cover, semanticLabel: slide.semanticLabel),

        // A designed banner carries its own words: no wash, no copy over it.
        if (!slide.isImageOnly) ...[
          if (scrim != null)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: scrim,
                ),
              ),
            ),
          // Centred in the slide above the controls row, as the website
          // centres its copy in the slide's height.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 76),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasEyebrow)
                  Text(slide.eyebrow!.toUpperCase(), style: AppText.eyebrow.copyWith(fontSize: 13)),
                if (hasTitle) ...[
                  const SizedBox(height: 10),
                  Flexible(
                    child: Text(
                      slide.title!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.h1.copyWith(
                        color: AppColors.primaryForeground,
                        fontSize: 30,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
                if (hasSubtitle) ...[
                  const SizedBox(height: 12),
                  Flexible(
                    child: Text(
                      slide.subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body.copyWith(
                        color: AppColors.primaryForeground.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
                if (slide.hasCta || slide.hasSecondaryCta) const SizedBox(height: 20),
                // Both full width, one above the other, as the website stacks
                // them on a phone.
                if (slide.hasCta)
                  FilledButton(
                    onPressed: () => openWebPath(context, slide.ctaUrl),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.accentForeground,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.field),
                      ),
                    ),
                    child: Text(slide.ctaLabel!, style: AppText.button),
                  ),
                if (slide.hasCta && slide.hasSecondaryCta) const SizedBox(height: 10),
                if (slide.hasSecondaryCta)
                  OutlinedButton(
                    onPressed: () => openWebPath(context, slide.secondaryCtaUrl),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryForeground,
                      side: BorderSide(
                        color: AppColors.primaryForeground.withValues(alpha: 0.4),
                      ),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.field),
                      ),
                    ),
                    child: Text(slide.secondaryCtaLabel!, style: AppText.button),
                  ),
              ],
            ),
          ),
        ] else
          // An image-only banner is a link as a whole, when it has one.
          if (slide.hasCta)
            Material(
              color: Colors.transparent,
              child: InkWell(onTap: () => openWebPath(context, slide.ctaUrl)),
            ),
      ],
    );
  }
}
