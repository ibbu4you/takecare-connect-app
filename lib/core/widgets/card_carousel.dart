library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A row of cards that snaps, one card at a time, with dots underneath.
///
/// The home page's three rows — stories, craftsmen, campaigns — were plain
/// horizontal lists. On a phone that reads as a strip that slid slightly and
/// stopped wherever your thumb left it: nothing lines up, the card you are
/// looking at is half off the screen, and there is no sign of how many more
/// there are.
///
/// This snaps each card to the same left edge, shows a sliver of the next so
/// it is obvious the row continues, and puts dots underneath so the length of
/// the row is visible before you swipe it. The website carries arrows for the
/// same reason; a phone has the swipe already and wants the position instead.
///
/// `padEnds: false` is what aligns the first card with the heading above it
/// rather than centring it — without that, a viewport fraction below 1 leaves
/// a gap down the left of the first card only, which reads as a mistake.
class CardCarousel extends StatefulWidget {
  const CardCarousel({
    super.key,
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
    this.viewportFraction = 0.82,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final double height;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// How much of the next card shows. 0.82 leaves about a fifth of it, which
  /// is enough to read as "there is more" without looking like a cut-off card.
  final double viewportFraction;

  final EdgeInsets padding;

  @override
  State<CardCarousel> createState() => _CardCarouselState();
}

class _CardCarouselState extends State<CardCarousel> {
  late final PageController _controller = PageController(
    viewportFraction: widget.viewportFraction,
  );

  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // One card needs no carousel and no dots — it would be a single dot under
    // a card that cannot move.
    if (widget.itemCount == 1) {
      return Padding(
        padding: widget.padding,
        child: SizedBox(height: widget.height, child: widget.itemBuilder(context, 0)),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            itemCount: widget.itemCount,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => Padding(
              // The gutter between cards is padding inside each one, so the
              // snap still lands the card's edge against the screen's margin.
              padding: EdgeInsets.only(
                left: widget.padding.left,
                right: i == widget.itemCount - 1 ? widget.padding.right : 0,
              ),
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: widget.itemBuilder(context, i),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.itemCount; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  width: i == _index ? 18 : 6,
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
