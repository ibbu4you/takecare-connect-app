library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/models/home.dart';
import '../../../core/router/web_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_image.dart';

/// The hero carousel.
///
/// Swipe-driven, with dots. Auto-advance is deliberately gentle — six seconds,
/// and it stops for good the moment the reader swipes, because a banner that
/// keeps moving under somebody reading it is an argument, not a feature.
///
/// Two things arrived with the website's footer strip and are honoured here for
/// the first time: the office's `overlay` choice, and a second call to action.
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key, required this.banners});

  final List<BannerSlide> banners;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();

    if (widget.banners.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 6), (_) {
        if (!mounted || !_controller.hasClients) return;

        final next = (_index + 1) % widget.banners.length;
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _stopAutoplay() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          // Portrait-ish, because the banners carry designed artwork that a
          // 16:9 letterbox would crop the words out of.
          aspectRatio: 4 / 3,
          child: NotificationListener<ScrollStartNotification>(
            onNotification: (_) {
              _stopAutoplay();

              return false;
            },
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.banners.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => BannerFrame(slide: widget.banners[i]),
            ),
          ),
        ),
        if (widget.banners.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.banners.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: i == _index ? 20 : 6,
                    decoration: BoxDecoration(
                      color: i == _index ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One banner.
///
/// It took an `aspectRatio` while the home page also drew the website's
/// before-footer strip. That band is not shown in the app — see the note in
/// home_screen.dart — so the only caller is the carousel above, which sizes
/// its own frame.
class BannerFrame extends StatelessWidget {
  const BannerFrame({super.key, required this.slide});

  final BannerSlide slide;

  Future<void> _open(BuildContext context, String? url) => openWebPath(context, url);

  /// The scrim, as the office asked for it.
  ///
  /// Three stops rather than a fade from the bottom third: white copy has to be
  /// legible over *any* photograph, including a pale one and including the
  /// placeholder showing while the image is still arriving. The first pass
  /// faded in only at the foot and left a three-line white headline sitting on
  /// near-white sky.
  List<Color> get _scrim => switch (slide.overlay) {
        BannerOverlay.none => const [Color(0x00000000), Color(0x00000000)],
        BannerOverlay.light => const [
            Color(0x140B1020),
            Color(0x4D0B1020),
            Color(0xB30B1020),
          ],
        BannerOverlay.heavy => const [
            Color(0x660B1020),
            Color(0xB30B1020),
            Color(0xFA0B1020),
          ],
        BannerOverlay.standard => const [
            Color(0x330B1020),
            Color(0x8A0B1020),
            Color(0xF20B1020),
          ],
      };

  @override
  Widget build(BuildContext context) {
    final frame = GestureDetector(
      onTap: () => _open(context, slide.ctaUrl),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppImage(
            url: slide.bestImage,
            fit: BoxFit.cover,
            semanticLabel: slide.semanticLabel,
          ),

          // A banner whose artwork already carries its words gets no scrim and
          // no overlaid copy — printing the title again over the top of a
          // designed poster is how the website used to look wrong. The office
          // can also ask for no scrim on a banner that does have words, which
          // is what `overlay: none` means.
          if (!slide.isImageOnly) ...[
            if (slide.overlay != BannerOverlay.none)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _scrim,
                    stops: _scrim.length == 3 ? const [0, 0.45, 1] : const [0, 1],
                  ),
                ),
                child: const SizedBox.expand(),
              ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (slide.eyebrow != null && slide.eyebrow!.isNotEmpty)
                    Text(slide.eyebrow!.toUpperCase(), style: AppText.eyebrow),
                  if (slide.title != null && slide.title!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      slide.title!,
                      style: AppText.h1.copyWith(color: Colors.white, fontSize: 23),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (slide.subtitle != null && slide.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      slide.subtitle!,
                      // Near-white, not the footer's muted blue-grey: that tone
                      // is legible on a flat navy band and disappears against a
                      // photograph.
                      style: AppText.excerpt.copyWith(color: const Color(0xE6FFFFFF)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (slide.hasCta || slide.hasSecondaryCta) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (slide.hasCta)
                          FilledButton(
                            onPressed: () => _open(context, slide.ctaUrl),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 42),
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                            ),
                            child: Text(slide.ctaLabel!),
                          ),
                        // The quieter of the two. Outlined in white because it
                        // sits on a photograph, where the theme's navy outline
                        // would disappear.
                        if (slide.hasSecondaryCta)
                          OutlinedButton(
                            onPressed: () => _open(context, slide.secondaryCtaUrl),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 42),
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0x66FFFFFF)),
                            ),
                            child: Text(slide.secondaryCtaLabel!),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );

    return frame;
  }
}
