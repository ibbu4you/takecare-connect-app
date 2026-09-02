import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_endpoints.dart';
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
///
/// **`src` and `href` are resolved against the site.** The editor writes
/// images into a body as `/storage/404/EN-1.png` — root-relative, which is
/// what a browser on the same host wants and what an app cannot use. Passed
/// through as-is they reach CachedNetworkImage as something that is not a URL
/// and every in-article photograph renders as a broken-image box. Hero and
/// thumbnail images arrive absolute from the API, so the two disagree and only
/// the body is affected.
class HtmlBody extends StatelessWidget {
  const HtmlBody(this.html, {super.key, this.textStyle, this.dropLeadingImage = false});

  final String? html;
  final TextStyle? textStyle;

  /// Drops a photograph the body opens with, for screens that are already
  /// showing it above.
  ///
  /// The editor sets a feature image and then starts the article with the same
  /// picture, so a story that renders both shows it twice running. Off by
  /// default: only the caller knows whether anything sits above it.
  final bool dropLeadingImage;

  @override
  Widget build(BuildContext context) {
    var source = html?.trim() ?? '';
    if (dropLeadingImage) source = _withoutLeadingImage(source);
    if (source.isEmpty) return const SizedBox.shrink();

    return HtmlWidget(
      source,
      textStyle: textStyle ?? AppText.body,
      // Resolves relative hrefs before onTapUrl sees them. Images do not go
      // through this — customWidgetBuilder reads the raw attribute — so they
      // are resolved by hand below.
      baseUrl: Uri.tryParse(Api.site),
      onTapUrl: (url) async {
        final uri = Uri.tryParse(url);
        if (uri == null) return false;

        return launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      customWidgetBuilder: (element) {
        if (element.localName != 'img') return null;

        final src = element.attributes['src'];
        if (src == null || src.isEmpty) return null;

        final url = _absolute(src);
        if (url == null) return null;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: AppImage(
            url: url,
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

  /// Strips an image the body opens with, and nothing else.
  ///
  /// Matches the three shapes the editor produces — a bare `<img>`, one
  /// wrapped in `<p>`, and one wrapped in `<figure>` — and only at the very
  /// start. A `<figure>` carrying a caption is left alone, because the caption
  /// is content the screen above is not showing.
  static String _withoutLeadingImage(String html) {
    final pattern = RegExp(
      r'^\s*(?:'
      r'<img\b[^>]*>'
      r'|<p[^>]*>\s*<img\b[^>]*>\s*</p>'
      r'|<figure[^>]*>\s*<img\b[^>]*>\s*</figure>'
      r')\s*',
      caseSensitive: false,
    );

    return html.replaceFirst(pattern, '').trim();
  }

  /// Resolves a body `src` against the site, leaving absolute URLs alone.
  ///
  /// `Uri.resolveUri` covers every form the editor produces: root-relative
  /// (`/storage/404/EN-1.png`), document-relative (`EN-1.png`) and
  /// protocol-relative (`//host/x.png`). Returns null for a `src` that is not
  /// a URI at all, so the `<img>` is dropped rather than rendered as a box.
  static String? _absolute(String src) {
    final uri = Uri.tryParse(src.trim());
    if (uri == null) return null;
    if (uri.hasScheme) return uri.toString();

    final site = Uri.tryParse(Api.site);
    if (site == null) return null;

    return site.resolveUri(uri).toString();
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
