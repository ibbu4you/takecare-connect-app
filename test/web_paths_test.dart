import 'package:flutter_test/flutter_test.dart';
import 'package:takecare_connect/core/router/web_paths.dart';

/// Every website path the server can hand the app, and where it should land.
///
/// This is the file that would have caught the original bug: the home screen's
/// programme cards call `context.go` on paths the API supplies, and three of
/// the four live ones — `/blog/category/tales-of-brands`,
/// `/interview-today`, and the external Pride of Humanity link — had no route
/// in the app. Nothing failed at build time; the reader simply got "that page
/// has moved" and no error reached a log.
///
/// The literal strings below are copied from the foundation's live navigation
/// and its `/home` payload, not invented.
void main() {
  group('stories', () {
    test('the blog index is the Stories tab', () {
      expect(appPathFor('/blog'), '/stories');
    });

    test('a category link opens the tab already filtered', () {
      expect(appPathFor('/blog/category/tales-of-brands'), '/stories?category=tales-of-brands');
      expect(appPathFor('/blog/category/her-stories'), '/stories?category=her-stories');
    });

    test('an author link opens their profile', () {
      expect(appPathFor('/blog/author/tcif-administrator'), '/authors/tcif-administrator');
    });

    test('an article opens the article', () {
      expect(appPathFor('/blog/a-weaver-in-bhuj'), '/stories/a-weaver-in-bhuj');
    });

    test('the RSS feed is not a screen', () {
      expect(appPathFor('/blog/feed'), isNull);
    });
  });

  group('craftsmen', () {
    test('both directory paths land on the tab', () {
      expect(appPathFor('/craftsmen'), '/craftsmen');
      expect(appPathFor('/businesses'), '/craftsmen');
    });

    test('the hub pages become filters', () {
      expect(appPathFor('/businesses/category/handicrafts'), '/craftsmen?category=handicrafts');
      expect(appPathFor('/businesses/city/chennai'), '/craftsmen?city=chennai');
    });

    test('an interview opens the interview', () {
      expect(appPathFor('/businesses/saran-castle'), '/craftsmen/saran-castle');
    });
  });

  group('give', () {
    test('campaigns map onto the Give tab', () {
      expect(appPathFor('/campaigns'), '/give');
      expect(appPathFor('/campaigns/a-kiln-for-anjali'), '/give/a-kiln-for-anjali');
    });

    test('the donate form carries its query through', () {
      expect(appPathFor('/donate'), '/donate');
      expect(appPathFor('/donate?campaign=a-kiln'), '/donate?campaign=a-kiln');
    });

    test("the web flow's own payment pages are not app screens", () {
      // The app has its own result screen, keyed on a reference it holds.
      expect(appPathFor('/donate/thanks'), isNull);
      expect(appPathFor('/donate/checkout/01JABC'), isNull);
    });

    test('a signed receipt PDF opens in a browser, not in the app', () {
      expect(appPathFor('/donations/12/receipt'), isNull);
    });
  });

  group('the More tab', () {
    test('every menu destination resolves', () {
      expect(appPathFor('/photo-gallery'), '/more/galleries');
      expect(appPathFor('/photo-gallery/launch-2026'), '/more/galleries/launch-2026');
      expect(appPathFor('/press-release'), '/more/press');
      expect(appPathFor('/about'), '/more/about');
      expect(appPathFor('/transparency'), '/more/transparency');
      expect(appPathFor('/contact'), '/more/contact');
      expect(appPathFor('/volunteer-opportunities'), '/more/volunteer');
      expect(appPathFor('/intern-opportunities'), '/more/intern');
      expect(appPathFor('/interview-today'), '/more/register-interview');
    });

    test('an unclaimed single segment is a static page', () {
      expect(appPathFor('/privacy-policy'), '/more/pages/privacy-policy');
      expect(appPathFor('/terms'), '/more/pages/terms');
      expect(appPathFor('/annual-reports'), '/more/pages/annual-reports');
      expect(appPathFor('/team'), '/more/pages/team');
    });
  });

  group('what should leave the app', () {
    test('an absolute URL belongs to somebody else', () {
      // This one is live in the header menu today.
      expect(appPathFor('https://prideofhumanity.com/poh-2nd-edition/'), isNull);
      expect(appPathFor('http://example.test/x'), isNull);
    });

    test('machine-readable paths are not screens', () {
      expect(appPathFor('/sitemap.xml'), isNull);
      expect(appPathFor('/robots.txt'), isNull);
    });

    test('nothing at all is nothing at all', () {
      expect(appPathFor(null), isNull);
      expect(appPathFor(''), isNull);
      expect(appPathFor('   '), isNull);
    });

    test('the site root is the home tab', () {
      expect(appPathFor('/'), '/');
    });
  });

  /// The four programmes the live `/home` endpoint returns today.
  ///
  /// Pinned as a set because they are the exact payload that was broken: only
  /// `/craftsmen` happened to match an app route, so three cards in four went
  /// nowhere.
  test('every live programme card has somewhere to go', () {
    const live = {
      '/craftsmen': '/craftsmen',
      '/blog/category/tales-of-brands': '/stories?category=tales-of-brands',
      '/interview-today': '/more/register-interview',
      '/volunteer-opportunities': '/more/volunteer',
    };

    live.forEach((webPath, expected) {
      expect(appPathFor(webPath), expected, reason: '$webPath went nowhere');
    });
  });
}
