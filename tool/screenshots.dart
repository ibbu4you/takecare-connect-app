import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takecare_connect/core/api/api_client.dart';
import 'package:takecare_connect/core/api/cursor_page.dart';
import 'package:takecare_connect/core/api/repository.dart';
import 'package:takecare_connect/core/models/business.dart';
import 'package:takecare_connect/core/models/campaign.dart';
import 'package:takecare_connect/core/models/donation.dart';
import 'package:takecare_connect/core/models/home.dart';
import 'package:takecare_connect/core/models/media.dart';
import 'package:takecare_connect/core/models/post.dart';
import 'package:takecare_connect/core/models/site.dart';
import 'package:takecare_connect/core/router/app_router.dart';
import 'package:takecare_connect/core/router/route_names.dart';
import 'package:takecare_connect/core/theme/app_theme.dart';

/// Renders every screen against the **live** API and writes a PNG per screen.
///
/// ```
/// flutter test tool/screenshots.dart
/// ```
///
/// Output goes to `build/screenshots/`. Not a golden test — nothing is compared
/// and nothing fails on a pixel change. It exists so the layout can be looked
/// at, because `flutter analyze` is perfectly happy with a card whose title
/// overflows, a section that renders blank because a key was renamed, or an
/// image that never arrives. None of those appear in a build log.
///
/// It drives the app's real router, so what comes out is what a phone shows,
/// tab bar and all.
void main() {
  late TestWidgetsFlutterBinding binding;

  late _Snapshot snapshot;

  setUpAll(() async {
    binding = TestWidgetsFlutterBinding.ensureInitialized();
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});

    // The test binding blocks all real HTTP outright.
    HttpOverrides.global = null;

    Directory('build/screenshots').createSync(recursive: true);

    // Fetched **here**, not inside the tests.
    //
    // `testWidgets` runs its body inside a fake-async zone, and dio's socket
    // machinery — timeouts, connection futures — is created in whichever zone
    // the client is built in. Inside the fake zone none of it ever fires, so a
    // widget test against the live API sits on its loading spinner forever
    // however long you pump. setUpAll has no such zone, so the network works
    // normally; each screenshot then runs against a repository that already
    // holds the answers and hands them back through Future.value, which a
    // single pump resolves.
    //
    // The data is still production's, which is the point — this catches a
    // section that renders blank because a key was renamed, not just a widget
    // that lays out.
    snapshot = await _Snapshot.fetch();
  });

  setUp(() async => _loadFonts());

  for (final screen in _screens) {
    testWidgets(screen.name, (tester) async {
      // Inside the test, not setUpAll: setSurfaceSize asserts `inTest`.
      // A phone, not the 800×600 the test binding defaults to.
      await binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => binding.setSurfaceSize(null));

      await tester.pumpWidget(_App(location: screen.location, snapshot: snapshot));

      // Alternating real delays and pumps, rather than one long wait.
      //
      // A live request completes on the root zone, but the microtask that
      // resolves the Future was created inside the test's fake-async zone and
      // only runs when the test pumps. So a single `runAsync(delay)` followed
      // by one `pump()` resolves the API call and leaves every image — each of
      // which starts its own request only once the widget that needs it has
      // been built — still in flight. pumpAndSettle is no use either: it would
      // spin forever on the progress indicator.
      await _settle(tester, _wait);

      if (screen.scrollBy > 0) {
        final scrollable = find.byType(Scrollable);

        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, Offset(0, -screen.scrollBy));
          // Images below the fold have only just been asked for.
          await _settle(tester, const Duration(seconds: 4));
        }
      }

      await _capture(tester, 'build/screenshots/${screen.file}.png');
    });
  }
}

/// Waits for live data and images by alternating real time with pumps.
Future<void> _settle(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 500);
  final rounds = (total.inMilliseconds / step.inMilliseconds).ceil();

  for (var i = 0; i < rounds; i++) {
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(step));
  }

  // A last frame with time on it, so any fade-in has finished.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Puts real glyphs on the screen.
///
/// `flutter test` replaces every font with a placeholder that draws each
/// character as a hollow box — right for a widget test that only measures
/// layout, useless for a screenshot. Nothing is registered unless it is loaded
/// explicitly, which is why the first run of this file produced pages of
/// rectangles.
///
/// Two families are needed:
///
/// **Material icons**, taken from the Flutter SDK's own cache. Without it every
/// icon in the app — the whole bottom bar — is a square.
///
/// **A text face**, registered under the names `google_fonts` would have used.
/// `GoogleFonts.dmSans()` names its family `DMSans_regular`, `DMSans_500` and
/// so on, and asks the platform to fetch it at runtime; that fetch needs
/// path_provider, which has no implementation in a test, so it silently gives
/// up. Registering a local face under those exact names is what makes the app's
/// own styles resolve. It is not DM Sans — metrics differ slightly — so these
/// screenshots are for reading the layout, never for judging kerning.
Future<void> _loadFonts() async {
  if (_fontsLoaded) return;
  _fontsLoaded = true;

  Future<void> register(String family, List<String> paths) async {
    final files = paths.map(File.new).where((f) => f.existsSync()).toList();
    if (files.isEmpty) return;

    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(Future.value(file.readAsBytesSync().buffer.asByteData()));
    }

    await loader.load();
  }

  const iconFont = r'C:\flutter\src\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf';
  const regular = r'C:\Windows\Fonts\segoeui.ttf';
  const bold = r'C:\Windows\Fonts\segoeuib.ttf';
  const semibold = r'C:\Windows\Fonts\segoeuisl.ttf';

  await register('MaterialIcons', [iconFont]);

  // Every weight AppText asks for, plus the bare family name.
  for (final entry in {
    'DMSans': regular,
    'DMSans_regular': regular,
    'DMSans_400': regular,
    'DMSans_500': semibold,
    'DMSans_600': semibold,
    'DMSans_700': bold,
  }.entries) {
    await register(entry.key, [entry.value]);
  }
}

bool _fontsLoaded = false;

class _Screen {
  const _Screen(this.name, this.location, this.file, {this.scrollBy = 0});

  final String name;
  final String location;
  final String file;

  /// How far to scroll before capturing, for screens whose interesting part is
  /// below the fold.
  final double scrollBy;
}

/// Long enough for the images on a screen to arrive.
const _wait = Duration(seconds: 5);

const _screens = [
  _Screen('home', Routes.home, '01-home'),
  _Screen('home scrolled', Routes.home, '02-home-scrolled', scrollBy: 800),
  _Screen('stories', Routes.stories, '03-stories'),
  _Screen('craftsmen', Routes.craftsmen, '04-craftsmen'),
  _Screen('give', Routes.give, '05-give'),
  _Screen('more', Routes.more, '06-more'),
  _Screen('more footer', Routes.more, '07-more-footer', scrollBy: 900),
  _Screen('about', '${Routes.more}/about', '08-about'),
  _Screen('transparency', '${Routes.more}/transparency', '09-transparency'),
  _Screen('contact', '${Routes.more}/contact', '10-contact'),
  _Screen('volunteer', '${Routes.more}/volunteer', '11-volunteer'),
  _Screen('register interview', '${Routes.more}/register-interview', '12-register'),
  _Screen('galleries', '${Routes.more}/galleries', '13-galleries'),
  _Screen('press', '${Routes.more}/press', '14-press'),
  _Screen('privacy page', '${Routes.more}/pages/privacy-policy', '15-page'),
  _Screen('donate', Routes.donate, '16-donate'),
  _Screen('search', '${Routes.home}search', '17-search'),
];

/// The app, rooted at one location and backed by the snapshot.
class _App extends StatelessWidget {
  const _App({required this.location, required this.snapshot});

  final String location;
  final _Snapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(_SnapshotRepository(snapshot)),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: buildRouter(initialLocation: location),
      ),
    );
  }
}

/// One live read of everything the screens ask for.
class _Snapshot {
  _Snapshot({
    required this.home,
    required this.settings,
    required this.formOptions,
    required this.posts,
    required this.postCategories,
    required this.businesses,
    required this.categories,
    required this.cities,
    required this.campaigns,
    required this.galleries,
    required this.press,
    required this.about,
    required this.transparency,
    required this.pages,
    required this.donationOptions,
  });

  final HomePayload home;
  final SiteSettings settings;
  final FormOptions formOptions;
  final CursorPage<PostSummary> posts;
  final List<TaxonomyOption> postCategories;
  final CursorPage<BusinessSummary> businesses;
  final List<TaxonomyOption> categories;
  final List<TaxonomyOption> cities;
  final CursorPage<Campaign> campaigns;
  final CursorPage<GallerySummary> galleries;
  final List<PressSection> press;
  final AboutContent about;
  final TransparencyData transparency;
  final Map<String, PageContent> pages;
  final DonationOptions donationOptions;

  static Future<_Snapshot> fetch() async {
    final repo = Repository(ApiClient());

    // ignore: avoid_print
    print('fetching live data from the API…');

    final pages = <String, PageContent>{};
    for (final slug in const ['privacy-policy', 'terms', 'refund-policy']) {
      pages[slug] = await repo.page(slug);
    }

    return _Snapshot(
      home: await repo.home(),
      settings: await repo.settings(),
      formOptions: await repo.formOptions(),
      posts: await repo.posts(),
      postCategories: await repo.postCategories(),
      businesses: await repo.businesses(),
      categories: await repo.categories(),
      cities: await repo.cities(),
      campaigns: await repo.campaigns(),
      galleries: await repo.galleries(),
      press: await repo.press(),
      about: await repo.about(),
      transparency: await repo.transparency(),
      pages: pages,
      donationOptions: await repo.donationOptions(),
    );
  }
}

/// Answers from the snapshot instead of the network.
///
/// Every list returns its first page with no cursor, so the infinite lists
/// stop at one page rather than trying to fetch a second that would never
/// arrive.
class _SnapshotRepository extends Repository {
  _SnapshotRepository(this._s) : super(ApiClient());

  final _Snapshot _s;

  static CursorPage<T> _onePage<T>(CursorPage<T> page) =>
      CursorPage<T>(items: page.items);

  @override
  Future<HomePayload> home() async => _s.home;

  @override
  Future<SiteSettings> settings() async => _s.settings;

  @override
  Future<FormOptions> formOptions() async => _s.formOptions;

  @override
  Future<CursorPage<PostSummary>> posts({
    String? category,
    String? author,
    String? query,
    String? cursor,
  }) async =>
      _onePage(_s.posts);

  @override
  Future<List<TaxonomyOption>> postCategories() async => _s.postCategories;

  @override
  Future<CursorPage<BusinessSummary>> businesses({
    String? category,
    String? city,
    String? query,
    String? cursor,
  }) async =>
      _onePage(_s.businesses);

  @override
  Future<List<TaxonomyOption>> categories() async => _s.categories;

  @override
  Future<List<TaxonomyOption>> cities() async => _s.cities;

  @override
  Future<CursorPage<Campaign>> campaigns({String? cursor}) async => _onePage(_s.campaigns);

  @override
  Future<CursorPage<GallerySummary>> galleries({String? cursor}) async =>
      _onePage(_s.galleries);

  @override
  Future<List<PressSection>> press() async => _s.press;

  @override
  Future<AboutContent> about() async => _s.about;

  @override
  Future<TransparencyData> transparency() async => _s.transparency;

  @override
  Future<PageContent> page(String slug) async =>
      _s.pages[slug] ?? PageContent(slug: slug, title: slug, body: null);

  /// Forced open.
  ///
  /// No payment gateway is enabled on the live site today, so the real answer
  /// is `donations_open: false` and the donate screen — correctly — renders its
  /// "Donations are paused" state. That is worth seeing once, but it hides the
  /// form itself, which is the screen with the most layout in it. The override
  /// is here in the screenshot harness and nowhere else; the app still believes
  /// whatever the server says.
  @override
  Future<DonationOptions> donationOptions() async => DonationOptions(
        currencies: _s.donationOptions.currencies,
        panThreshold: _s.donationOptions.panThreshold,
        suggestedAmounts: _s.donationOptions.suggestedAmounts,
        donationsOpen: true,
        internationalEnabled: _s.donationOptions.internationalEnabled,
      );
}

Future<void> _capture(WidgetTester tester, String path) async {
  final layer = tester.binding.rootElement!.renderObject!.debugLayer! as OffsetLayer;
  final bounds = tester.binding.rootElement!.renderObject!.paintBounds;

  // runAsync, because toImage waits on the raster thread and the fake async
  // zone would never deliver the callback.
  await tester.runAsync(() async {
    final image = await layer.toImage(bounds, pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
  });

  // ignore: avoid_print
  print('wrote $path');
}
