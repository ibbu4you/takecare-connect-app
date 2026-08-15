import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_image.dart';

/// Renders the raw HTML the API returns for `body`, `intro` and `story`.
///
/// The styling here is a deliberate transcription of the website's
/// `Components/Prose.tsx`, so a story reads the same in the app as in a
/// browser: 16px/1.6 paragraphs, tight-tracked bold headings, an accent-red
/// left rule on blockquotes, underlined navy links, rounded images with air
/// above and below.
///
/// Two behaviours worth knowing:
///
/// **Images are re-routed through [AppImage].** Without `customWidgetBuilder`
/// the package would use a plain `Image.network` for every `<img>` in the
/// article — no disk cache, no decode cap. An interview with fifteen
/// photographs would then re-download and full-size-decode all of them.
///
/// **Links open externally.** Anything in a body that points off-site is not
/// something the app has a screen for.
class HtmlBody extends StatelessWidget {
  const HtmlBody(this.html, {super.key, this.textStyle});

  final String? html;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final source = html?.trim() ?? '';
    if (source.isEmpty) return const SizedBox.shrink();

    return HtmlWidget(
      source,
      textStyle: textStyle ?? AppText.body,
      onTapUrl: (url) async {
        final uri = Uri.tryParse(url);
        if (uri == null) return false;

        return launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      customWidgetBuilder: (element) {
        if (element.localName != 'img') return null;

        final src = element.attributes['src'];
        if (src == null || src.isEmpty) return null;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: AppImage(
            url: src,
            radius: AppRadii.field,
            fit: BoxFit.cover,
            aspectRatio: _ratioOf(element.attributes),
            semanticLabel: element.attributes['alt'],
          ),
        );
      },
      // Longhand margins throughout, never the `margin: a b c` shorthand.
      // The package resolves `margin-top`/`margin-bottom` reliably and quietly
      // ignores the shorthand, which is why the first pass rendered headings
      // welded to the paragraph above them.
      customStylesBuilder: (element) {
        switch (element.localName) {
          case 'h2':
            return {
              'font-size': '22px',
              'font-weight': '700',
              'line-height': '1.25',
              'margin-top': '28px',
              'margin-bottom': '10px',
              'letter-spacing': '-0.4px',
            };
          case 'h3':
            return {
              'font-size': '18px',
              'font-weight': '700',
              'line-height': '1.3',
              'margin-top': '22px',
              'margin-bottom': '8px',
            };
          case 'h4':
            return {
              'font-size': '16px',
              'font-weight': '700',
              'margin-top': '18px',
              'margin-bottom': '6px',
            };
          case 'p':
            return {'margin-top': '0', 'margin-bottom': '16px'};
          case 'a':
            return {
              'color': '#283A8E',
              'text-decoration': 'underline',
              'font-weight': '500',
            };
          case 'strong':
          case 'b':
            return {'font-weight': '700'};
          case 'blockquote':
            return {
              'border-left': '3px solid #E63946',
              'padding-left': '16px',
              'margin-top': '20px',
              'margin-bottom': '20px',
              'font-style': 'italic',
              'color': '#5A6178',
            };
          case 'ul':
          case 'ol':
            return {'margin-bottom': '16px', 'padding-inline-start': '22px'};
          case 'li':
            return {'margin-bottom': '8px'};
          case 'figcaption':
            return {'font-size': '12px', 'color': '#5A6178', 'text-align': 'center'};
          case 'hr':
            return {'margin-top': '28px', 'margin-bottom': '28px'};
          case 'table':
            return {'font-size': '14px'};
          default:
            return null;
        }
      },
    );
  }

  /// Uses the dimensions the resource sends so the layout does not jump when
  /// the photograph arrives. Falls back to null — meaning "size yourself" —
  /// rather than guessing 16:9 and letterboxing a portrait.
  static double? _ratioOf(Map<Object, String> attributes) {
    final w = double.tryParse(attributes['width'] ?? '');
    final h = double.tryParse(attributes['height'] ?? '');

    return (w != null && h != null && h > 0) ? w / h : null;
  }
}
