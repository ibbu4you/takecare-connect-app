library;

import 'package:flutter/material.dart';

import '../../../core/models/home.dart';
import '../../../core/router/web_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_image.dart';

/*
 | The strip the office sets above the website's footer — FooterBanner.tsx.
 |
 | The footer itself is not drawn in the app, at the office's request: on a
 | phone the bottom tabs and the menu already carry everything it links to.
 */

/// The strip above the footer, from Content → Hero banners ("before footer").
///
/// A designed banner, whose words are in the artwork, is shown at its own
/// shape and never cropped — the website stopped cropping it after the bottom
/// of the first one uploaded went missing. Anything else is a navy band with
/// its words and buttons.
class FooterBannerBand extends StatelessWidget {
  const FooterBannerBand({super.key, required this.banner});

  final BannerSlide banner;

  @override
  Widget build(BuildContext context) {
    if (banner.isImageOnly) {
      final picture = AppImage(
        url: banner.bestImage,
        fit: BoxFit.fitWidth,
        semanticLabel: banner.semanticLabel,
      );

      return ColoredBox(
        color: AppColors.primary,
        child: banner.hasCta
            ? InkWell(onTap: () => openWebPath(context, banner.ctaUrl), child: picture)
            : picture,
      );
    }

    return ColoredBox(
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (banner.eyebrow?.isNotEmpty ?? false) ...[
              Text(banner.eyebrow!.toUpperCase(), style: AppText.eyebrow),
              const SizedBox(height: 10),
            ],
            if (banner.title?.isNotEmpty ?? false)
              Text(banner.title!, style: AppText.h2.copyWith(color: AppColors.primaryForeground)),
            if (banner.subtitle?.isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              Text(
                banner.subtitle!,
                style: AppText.body.copyWith(
                  color: AppColors.primaryForeground.withValues(alpha: 0.8),
                ),
              ),
            ],
            if (banner.hasCta) ...[
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => openWebPath(context, banner.ctaUrl),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.accentForeground,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(banner.ctaLabel!, style: AppText.button),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
