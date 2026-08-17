import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The foundation's logo.
///
/// The real mark: a navy roundel with the foundation's name around the rim, a
/// laurel wreath, two hearts, and a TCIF ribbon. Bundled as an asset rather
/// than fetched, so it is instant, works offline, and is the same image the
/// launcher icon is cut from — `tool/generate_icons.dart` builds those from
/// this exact file.
///
/// It is a **raster** badge with fine rim lettering, which changes two things
/// from a vector mark:
///
/// **It cannot be recoloured.** There is no `color` here on purpose. A tint on
/// a multi-colour badge would either do nothing or ruin it, and quietly
/// accepting a colour that gets ignored is worse than not offering one.
///
/// **It needs a light ground.** The badge is navy, so on the footer's dark
/// band it would all but vanish. [onDark] puts it on a white disc instead,
/// which is the standard treatment for a circular badge and reads as
/// deliberate rather than as a bug.
class TcifLogo extends StatelessWidget {
  const TcifLogo({super.key, this.size = 36, this.onDark = false});

  final double size;

  /// Sets the badge on a white disc, for the footer and any other dark ground.
  final bool onDark;

  static const asset = 'assets/brand/tcif_logo.png';

  @override
  Widget build(BuildContext context) {
    // cacheWidth, because the asset is 379px square and most uses are 30–60.
    // Without it every instance decodes at full size into the image cache.
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();

    Widget mark = Image.asset(
      asset,
      width: size,
      height: size,
      cacheWidth: pixels,
      cacheHeight: pixels,
      filterQuality: FilterQuality.medium,
      // The mark is the brand; a screen reader should hear the foundation's
      // name rather than "image".
      semanticLabel: 'Take Care International Foundation',
    );

    if (onDark) {
      mark = Container(
        // The disc is a touch larger than the badge so the navy rim is not
        // flush against the dark background.
        padding: EdgeInsets.all(size * 0.06),
        decoration: const BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
        ),
        child: mark,
      );
    }

    return mark;
  }
}
