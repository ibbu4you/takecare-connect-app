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
      await binding.setSurfaceSize(screen.size);
      addTearDown(() => binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _App(
          location: screen.locationFor(snapshot),
          snapshot: snapshot,
          textScale: screen.textScale,
        ),
      );

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

      if (screen.scrolls) {
        final scrollable = find.byType(Scrollable);

        if (scrollable.evaluate().isNotEmpty) {
          // jumpTo, not drag.
          //
          // A drag hands the list a ballistic animation, and `pump()` advances
          // animation time by zero — so the capture lands mid-fling, past
          // maxScrollExtent, and the screenshot is a card floating above a
          // screenful of overscrolled white. Clamping to the real extent and
          // jumping there is exact and needs no settling.
          // Twice, because a lazy ListView only knows the extent of what it has
          // already built. The first jump lands near the end of the known
          // content, which builds the rest; the second reaches the actual
          // bottom. One jump leaves a screenful of white below the last card.
          for (var i = 0; i < 2; i++) {
            final position = tester.state<ScrollableState>(scrollable.first).position;

            final target = screen.scrollFromEnd > 0
                ? position.maxScrollExtent - screen.scrollFromEnd
                : screen.scrollBy;

            position.jumpTo(target.clamp(0.0, position.maxScrollExtent));

            // Images below the fold have only just been asked for.
            await _settle(tester, const Duration(seconds: 3));
          }
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
  const _Screen(
    this.name,
    this.location,
    this.file, {
    this.scrollBy = 0,
    this.scrollFromEnd = 0,
    this.slugFrom,
    this.size = const Size(390, 844),
    this.textScale = 1.0,
  });

  final String name;
  final String location;
  final String file;

  /// How far to scroll before capturing, for screens whose interesting part is
  /// below the fold.
  final double scrollBy;

  /// How far back from the bottom to stop.
  ///
  /// For anything positioned relative to the end of a page whose length depends
  /// on how long today's article happens to be — a fixed offset would land
  /// somewhere different every time the content changed.
  final double scrollFromEnd;

  bool get scrolls => scrollBy > 0 || scrollFromEnd > 0;

  /// Pulls a real slug out of the snapshot for a detail screen.
  ///
  /// Tests have to be registered synchronously from `main()`, before `setUpAll`
  /// has fetched anything — so a detail route cannot be a constant. The screen
  /// declares how to find its slug and resolves it inside the test body.
  final String Function(_Snapshot)? slugFrom;

  /// The viewport. Defaults to a mainstream phone; set it smaller to prove a
  /// screen survives the narrowest one people still carry.
  final Size size;

  /// The system font scale, which the app clamps to 1.3. Worth pushing to that
  /// ceiling on anything crowded — an app bar overflowed on a real device and
  /// no screenshot at 1.0 would ever have shown it.
  final double textScale;

  String locationFor(_Snapshot snapshot) {
    final slug = slugFrom?.call(snapshot);

    return slug == null || slug.isEmpty ? location : '$location/$slug';
  }
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

  // The detail screens, on whatever the site is publishing today.
  _Screen('story', Routes.stories, '18-story', slugFrom: _firstStory),
  // Far enough to clear the article body and land on the share bar, the author
  // box, and everything the page closes with.
  _Screen('story footer', Routes.stories, '19-story-footer',
      slugFrom: _firstStory, scrollBy: 99999),
  _Screen('craftsman', Routes.craftsmen, '20-craftsman', slugFrom: _firstCraftsman),
  _Screen('campaign', Routes.give, '21-campaign', slugFrom: _firstCampaign),
  // Where the share bar and the author box sit, measured back from the end so
  // it lands in the same place however long today's article runs.
  _Screen('story author', Routes.stories, '22-story-author',
      slugFrom: _firstStory, scrollFromEnd: 1480),

  // The squeeze test: the narrowest phone still in use, with the system font at
  // the ceiling the app allows. This is the combination that overflowed the
  // home app bar on a real device, and no screenshot at 390pt and 1.0 would
  // ever have shown it.
  _Screen('home squeezed', Routes.home, '23-home-squeezed',
      size: Size(320, 640), textScale: 1.3),
  _Screen('more squeezed', Routes.more, '24-more-squeezed',
      size: Size(320, 640), textScale: 1.3),

  // Step 2 of the donate form, where the PAN field lives — offered on every
  // INR donation, required only above the threshold.
  _Screen('donate details', Routes.donate, '25-donate-details', scrollBy: 950),

  // The four that had never been rendered at all.
  _Screen('intern', '${Routes.more}/intern', '26-intern'),
  _Screen('author', '/authors', '27-author', slugFrom: _firstAuthor),
  _Screen('gallery', '${Routes.more}/galleries', '28-gallery', slugFrom: _firstGallery),
  _Screen('donate result', '/donate/result', '29-donate-result', slugFrom: _anyReference),
];

String _firstStory(_Snapshot s) => s.posts.items.isEmpty ? '' : s.posts.items.first.slug;

String _firstCraftsman(_Snapshot s) =>
    s.businesses.items.isEmpty ? '' : s.businesses.items.first.slug;

String _firstCampaign(_Snapshot s) =>
    s.campaigns.items.isEmpty ? '' : s.campaigns.items.first.slug;

String _firstAuthor(_Snapshot s) => s.authors.keys.isEmpty ? '' : s.authors.keys.first;

String _firstGallery(_Snapshot s) =>
    s.galleries.items.isEmpty ? '' : s.galleries.items.first.slug;

/// Any reference at all — the snapshot repository answers every one with the
/// same paid donation, because the point is the screen, not the lookup.
String _anyReference(_Snapshot s) => '01JEXAMPLEREFERENCE';

/// The app, rooted at one location and backed by the snapshot.
class _App extends StatelessWidget {
  const _App({
    required this.location,
    required this.snapshot,
    this.textScale = 1.0,
  });

  final String location;
  final _Snapshot snapshot;
  final double textScale;

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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
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
    required this.trending,
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
    required this.postDetails,
    required this.businessDetails,
    required this.campaignDetails,
    required this.authors,
    required this.galleryDetails,
  });

  final HomePayload home;
  final SiteSettings settings;
  final FormOptions formOptions;
  final CursorPage<PostSummary> posts;
  final List<TaxonomyOption> postCategories;
  final List<PostSummary> trending;
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

  /// The detail screens, fetched for whatever the site is publishing today.
  final Map<String, PostDetail> postDetails;
  final Map<String, BusinessDetail> businessDetails;
  final Map<String, Campaign> campaignDetails;
  final Map<String, AuthorProfile> authors;
  final Map<String, GalleryDetail> galleryDetails;

  static Future<_Snapshot> fetch() async {
    final repo = Repository(ApiClient());

    // ignore: avoid_print
    print('fetching live data from the API…');

    final pages = <String, PageContent>{};
    for (final slug in const ['privacy-policy', 'terms', 'refund-policy']) {
      pages[slug] = await repo.page(slug);
    }

    // Tolerated rather than required: this endpoint is newer than the deployed
    // server may be, and a 404 here should cost one empty section rather than
    // every screenshot in the run.
    var trending = <PostSummary>[];
    try {
      trending = await repo.trendingStories();
    } catch (e) {
      // ignore: avoid_print
      print('  (trending unavailable: $e)');
    }

    final posts = await repo.posts();
    final businesses = await repo.businesses();
    final campaigns = await repo.campaigns();
    final galleries = await repo.galleries();

    // Only the first of each: these are what the detail screenshots open, and
    // fetching every one would turn a twenty-second run into a crawl.
    final postDetails = <String, PostDetail>{};
    final authors = <String, AuthorProfile>{};

    if (posts.items.isNotEmpty) {
      final slug = posts.items.first.slug;
      postDetails[slug] = await repo.post(slug);

      final authorSlug = postDetails[slug]!.author?.slug;
      if (authorSlug != null) authors[authorSlug] = await repo.author(authorSlug);
    }

    final businessDetails = <String, BusinessDetail>{};
    if (businesses.items.isNotEmpty) {
      final slug = businesses.items.first.slug;
      businessDetails[slug] = await repo.business(slug);
    }

    final galleryDetails = <String, GalleryDetail>{};
    if (galleries.items.isNotEmpty) {
      final slug = galleries.items.first.slug;
      galleryDetails[slug] = await repo.gallery(slug);
    }

    final campaignDetails = <String, Campaign>{};
    if (campaigns.items.isNotEmpty) {
      final slug = campaigns.items.first.slug;
      campaignDetails[slug] = await repo.campaign(slug);
    }

    return _Snapshot(
      home: await repo.home(),
      settings: await repo.settings(),
      formOptions: await repo.formOptions(),
      posts: posts,
      postCategories: await repo.postCategories(),
      trending: trending,
      businesses: businesses,
      categories: await repo.categories(),
      cities: await repo.cities(),
      campaigns: campaigns,
      galleries: galleries,
      press: await repo.press(),
      about: await repo.about(),
      transparency: await repo.transparency(),
      pages: pages,
      donationOptions: await repo.donationOptions(),
      postDetails: postDetails,
      businessDetails: businessDetails,
      campaignDetails: campaignDetails,
      authors: authors,
      galleryDetails: galleryDetails,
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
  Future<List<PostSummary>> trendingStories({String? exclude}) async =>
      _s.trending.where((p) => p.slug != exclude).toList();

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
  Future<GalleryDetail> gallery(String slug) async =>
      _s.galleryDetails[slug] ?? (throw StateError('no snapshot for gallery $slug'));

  /// A donation that went through, so the success screen has something to draw.
  ///
  /// Invented rather than fetched: there is no paid donation on production to
  /// point at, and the one screen a donor sees after paying is the last one
  /// that should go unlooked-at.
  @override
  Future<DonationStatus> donationStatus(String reference) async => DonationStatus(
        status: 'paid',
        isPending: false,
        amount: 2500,
        currency: 'INR',
        receiptNumber: 'TCIF/2026/0042',
        receiptUrl: 'https://takecareconnect.com/donations/r/$reference/receipt?signature=x',
        paidAt: DateTime(2026, 8, 20),
      );

  // The detail screens. A miss throws rather than falling back to the network:
  // inside a widget test's fake-async zone a real request never completes, so
  // silently reaching for one would hang the run with no explanation.
  @override
  Future<PostDetail> post(String slug) async =>
      _s.postDetails[slug] ?? (throw StateError('no snapshot for post $slug'));

  @override
  Future<BusinessDetail> business(String slug) async =>
      _s.businessDetails[slug] ?? (throw StateError('no snapshot for business $slug'));

  @override
  Future<Campaign> campaign(String slug) async =>
      _s.campaignDetails[slug] ?? (throw StateError('no snapshot for campaign $slug'));

  @override
  Future<AuthorProfile> author(String slug) async =>
      _s.authors[slug] ?? (throw StateError('no snapshot for author $slug'));

  @override
  Future<AboutContent> about() async => _s.about;

  @override
  Future<TransparencyData> transparency() async => _s.transparency;

  @override
  Future<PageContent> page(String slug) async =>
      _s.pages[slug] ?? PageContent(slug: slug, title: slug, body: null);

  /// Passed through unchanged, including `donations_open: false`.
  ///
  /// This used to be forced open, because the screen replaced the entire form
  /// with a "paused" message and there was otherwise nothing to photograph. Now
  /// that the form renders either way — with a banner over it, as the website
  /// does — the honest answer is also the useful one, and the screenshot shows
  /// what a donor actually sees today.
  @override
  Future<DonationOptions> donationOptions() async => _s.donationOptions;
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
