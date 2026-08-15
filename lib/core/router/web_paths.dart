import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_endpoints.dart';
import 'route_names.dart';

/// Follows a link the server gave us, wherever it leads.
///
/// A path the app can show is routed to; anything else — an external site, an
/// RSS feed, the signed receipt PDF — opens in the browser against the site's
/// own host. Screens call this rather than `context.go` so that no caller has
/// to know which kind of link it is holding.
Future<void> openWebPath(BuildContext context, String? webPath) async {
  final raw = webPath?.trim() ?? '';
  if (raw.isEmpty) return;

  final appPath = appPathFor(raw);

  if (appPath != null) {
    context.go(appPath);

    return;
  }

  final uri = Uri.tryParse(raw.startsWith('http') ? raw : Api.webUrl(raw));
  if (uri == null) return;

  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Translates a **website** path into the app route that shows the same thing.
///
/// The API hands out site-relative paths in several places — banner calls to
/// action, the programme cards on the home screen, and anything an editor types
/// into a link. Those paths are the website's: `/blog/category/tales-of-brands`,
/// `/photo-gallery`, `/interview-today`. The app's routes are not the same
/// strings, and passing one straight to `context.go` lands the reader on the
/// "that page has moved" screen — which is exactly what happened to three of
/// the four programme cards before this existed.
///
/// Returns null when there is nothing in the app to show, which is the caller's
/// cue to open the link in a browser instead.
///
/// **Kept in one place on purpose.** The mapping was originally inlined in the
/// banner widget, which meant the programme cards silently had none. Anything
/// that receives a path from the server routes through here.
String? appPathFor(String? webPath) {
  final raw = webPath?.trim() ?? '';
  if (raw.isEmpty) return null;

  // Anything absolute belongs to somebody else's site.
  if (raw.startsWith('http://') || raw.startsWith('https://')) return null;

  final uri = Uri.tryParse(raw);
  if (uri == null) return null;

  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return Routes.home;

  final query = uri.query.isEmpty ? '' : '?${uri.query}';

  switch (segments.first) {
    // ------------------------------------------------------------- Stories
    case 'blog':
      if (segments.length == 1) return Routes.stories;

      // /blog/category/{slug} is a page of its own on the web; in the app it
      // is the Stories tab with that filter already applied.
      if (segments[1] == 'category' && segments.length > 2) {
        return '${Routes.stories}?category=${segments[2]}';
      }

      if (segments[1] == 'author' && segments.length > 2) {
        return Routes.author(segments[2]);
      }

      // /blog/feed is an RSS document, not a screen.
      if (segments[1] == 'feed') return null;

      return Routes.story(segments[1]);

    // ----------------------------------------------------------- Craftsmen
    case 'craftsmen':
      return Routes.craftsmen;

    case 'businesses':
      if (segments.length == 1) return Routes.craftsmen;

      if (segments[1] == 'category' && segments.length > 2) {
        return '${Routes.craftsmen}?category=${segments[2]}';
      }

      if (segments[1] == 'city' && segments.length > 2) {
        return '${Routes.craftsmen}?city=${segments[2]}';
      }

      return Routes.craftsman(segments[1]);

    // ---------------------------------------------------------- Campaigns
    case 'campaigns':
      return segments.length == 1 ? Routes.give : Routes.campaign(segments[1]);

    case 'donate':
      // /donate/thanks and /donate/checkout are the web payment flow's own
      // pages; the app has its own result screen keyed on a reference it holds.
      return segments.length == 1 ? '${Routes.donate}$query' : null;

    // -------------------------------------------------------------- Media
    case 'photo-gallery':
      return segments.length == 1
          ? '${Routes.more}/galleries'
          : '${Routes.more}/galleries/${segments[1]}';

    case 'press-release':
      return '${Routes.more}/press';

    // ------------------------------------------------------ The foundation
    case 'about':
      return '${Routes.more}/about';

    case 'transparency':
      return '${Routes.more}/transparency';

    case 'contact':
      return '${Routes.more}/contact';

    // --------------------------------------------------------- Take part
    case 'volunteer-opportunities':
      return '${Routes.more}/volunteer';

    case 'intern-opportunities':
      return '${Routes.more}/intern';

    case 'interview-today':
      return '${Routes.more}/register-interview';

    // ------------------------------------------------------------- Other
    // Machine-readable, or the donor's signed receipt PDF — none of which is a
    // screen. The receipt in particular must open in a browser: its URL is
    // signed and expiring, and it renders a PDF.
    case 'sitemap.xml':
    case 'robots.txt':
    case 'donations':
      return null;

    default:
      // Everything left is the website's catch-all static page route, which is
      // the app's /more/pages/{slug}. A single unknown segment is the only
      // shape that can be one.
      return segments.length == 1 ? '${Routes.more}/pages/${segments.first}' : null;
  }
}
