import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takecare_connect/core/models/navigation.dart';
import 'package:takecare_connect/core/router/web_paths.dart';
import 'package:takecare_connect/core/state/providers.dart';
import 'package:takecare_connect/core/theme/app_theme.dart';
import 'package:takecare_connect/core/widgets/site_menu.dart';

/// The ☰ menu, which is the website's header menu.
///
/// The menu below is the website's, as `/navigation` sends it today. The tests
/// hold that it is drawn item for item, that its lists open in place — three
/// levels, for "100 Most Inspiring Startup" › "Register" — and that every link
/// in it lands on a screen of the app's own rather than in a browser, except
/// the one that really is another website.
void main() {
  NavItem item(String label, [String? url, List<NavItem> children = const [], bool external = false]) =>
      NavItem(label: label, url: url, children: children, external: external);

  final websiteMenu = [
    item('Our Programs', null, [
      item('Pride of Humanity', 'https://prideofhumanity.com/poh-2nd-edition/', const [], true),
      item('Craftsmen', '/craftsmen'),
      item('Tales of Brands', '/blog/category/tales-of-brands'),
      item('100 Most Inspiring Startup', null, [item('Register', '/interview-today')]),
      item('Campaigns', '/campaigns'),
    ]),
    item('Shop', '/shop'),
    item('Brands', '/brands'),
    item('Influencing Narratives', '/blog', [
      item('Startup stories', '/blog/category/startup-stories'),
      item('Social stories', '/blog/category/social-stories'),
      item('Her stories', '/blog/category/her-stories'),
      item('Enterprise stories', '/blog/category/enterprise-stories'),
      item('Education stories', '/blog/category/education-stories'),
      item('AI Stories', '/blog/category/ai-stories'),
    ]),
    item('Join our community', null, [
      item('For Volunteers', '/volunteer-opportunities'),
      item('Intern Opportunities', '/intern-opportunities'),
    ]),
    item('News and Media', null, [
      item('Photo', '/photo-gallery'),
      item('Press Release', '/press-release'),
    ]),
    item('Reach Us', '/contact'),
    item('About Us', '/about'),
  ];

  Future<void> pump(WidgetTester tester, {double width = 390, double scale = 1}) async {
    await tester.binding.setSurfaceSize(Size(width, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navigationProvider.overrideWith((ref) => websiteMenu)],
        child: MaterialApp(
          theme: AppTheme.light(),
          builder: (context, inner) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: inner!,
          ),
          home: Builder(
            builder: (host) => Scaffold(
              endDrawer: SiteMenu(host: host),
              body: Builder(
                builder: (inner) => TextButton(
                  onPressed: () => Scaffold.of(inner).openEndDrawer(),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('the top level is the website\'s, in its order', (tester) async {
    await pump(tester);

    var previous = double.negativeInfinity;

    for (final top in websiteMenu) {
      final finder = find.text(top.label);
      expect(finder, findsOneWidget, reason: '"${top.label}" is missing');

      final y = tester.getTopLeft(finder).dy;
      expect(y, greaterThan(previous), reason: '"${top.label}" is out of order');
      previous = y;
    }

    expect(find.text('Donate'), findsOneWidget);
  });

  testWidgets('a list opens in place, three levels deep', (tester) async {
    await pump(tester);

    expect(find.text('Craftsmen'), findsNothing, reason: 'lists start closed');

    await tester.tap(find.text('Our Programs'));
    await tester.pumpAndSettle();

    expect(find.text('Craftsmen'), findsOneWidget);
    expect(find.text('Register'), findsNothing);

    await tester.tap(find.text('100 Most Inspiring Startup'));
    await tester.pumpAndSettle();

    expect(find.text('Register'), findsOneWidget);
  });

  /// Influencing Narratives is /blog as well as a list, so it gets a row of
  /// its own — tapping its heading opens the list rather than the page.
  testWidgets('a heading that is also a page offers the page', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Influencing Narratives'));
    await tester.pumpAndSettle();

    expect(find.text('Influencing Narratives overview'), findsOneWidget);
    expect(find.text('AI Stories'), findsOneWidget);
  });

  testWidgets('every list open at once still fits a small phone at 1.3x text', (tester) async {
    await pump(tester, width: 320, scale: 1.3);

    for (final heading in ['Our Programs', 'Influencing Narratives', 'Join our community', 'News and Media']) {
      await tester.ensureVisible(find.text(heading));
      await tester.tap(find.text(heading));
      await tester.pumpAndSettle();
    }

    expect(tester.takeException(), isNull);
  });

  /// The menu's links are the website's paths. Each must open a screen of the
  /// app's — a null here would send the reader to a browser for a page the app
  /// can show. Only Pride of Humanity, another website, should leave.
  test('every link in the website\'s menu lands on an app screen', () {
    Iterable<NavItem> walk(List<NavItem> items) sync* {
      for (final entry in items) {
        yield entry;
        yield* walk(entry.children);
      }
    }

    for (final entry in walk(websiteMenu)) {
      if (entry.url == null) continue;

      if (entry.external) {
        expect(appPathFor(entry.url!), isNull, reason: '${entry.label} is another website');
      } else {
        expect(appPathFor(entry.url!), isNotNull, reason: '${entry.label} (${entry.url}) has no app screen');
      }
    }
  });
}
