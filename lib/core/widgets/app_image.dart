import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Every remote image in the app goes through here.
///
/// Two things it does that a bare `Image.network` would not:
///
/// **Caches to disk.** Scrolling back up a list should not re-download the
/// photographs, which on an Indian mobile connection is the difference between
/// an app that feels quick and one that costs money to use.
///
/// **Caps the decode size.** This is not optional. The API returns a bare URL
/// and the *server* picks the conversion, so a detail screen is handed a
/// 1600px hero whatever the widget is. Without `memCacheWidth` Flutter decodes
/// every one at full size into the image cache, and a gallery of a dozen
/// photographs will exhaust memory on a mid-range Android phone.
///
/// [url] is nullable by design rather than by accident: every image field in
/// this API can come back null, so a missing photograph is the normal case and
/// gets a considered placeholder rather than a crash.
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.url,
    this.aspectRatio,
    this.radius = 0,
    this.fit = BoxFit.cover,
    this.semanticLabel,
  });

  final String? url;
  final double? aspectRatio;
  final double radius;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    Widget child = LayoutBuilder(
      builder: (context, constraints) {
        if (url == null || url!.isEmpty) return const _Placeholder();

        final dpr = MediaQuery.devicePixelRatioOf(context);
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 800.0;

        return CachedNetworkImage(
          imageUrl: url!,
          fit: fit,
          memCacheWidth: (width * dpr).round(),
          fadeInDuration: const Duration(milliseconds: 200),
          fadeOutDuration: Duration.zero,
          placeholder: (_, __) => const _Placeholder(),
          errorWidget: (_, __, ___) => const _Placeholder(failed: true),
        );
      },
    );

    if (aspectRatio != null) {
      child = AspectRatio(aspectRatio: aspectRatio!, child: child);
    }

    if (radius > 0) {
      child = ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);
    }

    return semanticLabel == null
        ? child
        : Semantics(image: true, label: semanticLabel, child: child);
  }
}

/// The empty and failed state.
///
/// A flat tinted panel with a plain glyph, rather than a shimmer: this design
/// system carries elevation with borders, and a pulsing grey block is the
/// wrong texture for it.
///
/// An icon rather than the logo. The badge is a detailed roundel with rim
/// lettering; faded to 15% behind a card it reads as a smudge, and repeated
/// down a list of a dozen loading images it makes the whole screen look
/// broken. A single quiet glyph says "picture" without pretending to be brand.
class _Placeholder extends StatelessWidget {
  const _Placeholder({this.failed = false});

  final bool failed;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: Center(
        child: Icon(
          failed ? Icons.image_not_supported_outlined : Icons.image_outlined,
          size: 26,
          color: AppColors.border,
        ),
      ),
    );
  }
}
