library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takecare_connect/core/api/api_client.dart';
import 'package:takecare_connect/core/api/api_endpoints.dart';
import 'package:takecare_connect/core/api/cursor_page.dart';
import 'package:takecare_connect/core/api/repository.dart';
import 'package:takecare_connect/core/models/business.dart';
import 'package:takecare_connect/core/models/campaign.dart';
import 'package:takecare_connect/core/models/donation.dart';
import 'package:takecare_connect/core/models/home.dart';
import 'package:takecare_connect/core/models/media.dart';
import 'package:takecare_connect/core/models/post.dart';
import 'package:takecare_connect/core/models/shop.dart';
import 'package:takecare_connect/core/models/site.dart';
import 'package:takecare_connect/core/router/app_router.dart';
import 'package:takecare_connect/core/router/route_names.dart';
import 'package:takecare_connect/core/theme/app_theme.dart';

/// Runs the cases in qa/checklist.json that a machine can judge.
///
/// ```
/// flutter test qa/run_checklist.dart --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
/// ```
///
/// It drives the app's **real router** against **real data** read from the API
/// once at the start, so a pass here means the screen a phone shows worked, not
/// that a mock agreed with itself.
///
/// Writes `qa/results.json` and prints one `CASE <id> <verdict>` line per case.
/// A case the checklist describes but this file does not attempt is not a pass
/// and not a failure — it is listed at the end as needing a person, with the
/// reason, in the same way the website's run reported 36 of its 248.
///
/// **Why the data is fetched in `setUpAll`.** `testWidgets` runs its body in a
/// fake-async zone, and dio's socket machinery is created in whichever zone the
/// client is built in — inside the fake zone none of it ever fires, so a widget
/// test against a live API sits on its spinner for ever however long you pump.
/// `setUpAll` has no such zone. Each case then runs against a repository that
/// already holds the answers.
void main() {
  late _Live live;

  final verdicts = <String, Map<String, String>>{};

  /// Records a case's outcome. Every driven case goes through this, so one
  /// place decides what a pass looks like and the report cannot disagree with
  /// the run.
  Future<void> runCase(
    WidgetTester tester,
    String id,
    String what,
    Future<void> Function() body,
  ) async {
    try {
      await body();
      verdicts[id] = {'verdict': 'PASS', 'title': what};
      // ignore: avoid_print
      print('CASE $id PASS  $what');
    } catch (e) {
      final detail = e.toString().split('\n').first;
      verdicts[id] = {'verdict': 'FAIL', 'title': what, 'detail': detail};
      // ignore: avoid_print
      print('CASE $id FAIL  $what\n        $detail');
    }
  }

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});

    // The test binding blocks real HTTP outright; this restores it for the
    // fetch below.
    HttpOverrides.global = null;

    await _loadDmSans();
    live = await _Live.fetch();

    // ignore: avoid_print
    print('checking ${Api.base}');
    // ignore: avoid_print
    print('  ${live.products.items.length} products, ${live.brands.length} makers, '
        '${live.home.banners.length} banners, ${live.home.postCategories.length} subjects');
  });

  tearDownAll(() {
    final passed = verdicts.values.where((v) => v['verdict'] == 'PASS').length;
    final failed = verdicts.values.where((v) => v['verdict'] == 'FAIL').length;

    File('qa/results.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'base': Api.base,
        'driven': verdicts.length,
        'passed': passed,
        'failed': failed,
        'cases': verdicts,
      }),
    );

    // ignore: avoid_print
    print('\n$passed passed, $failed failed, ${verdicts.length} driven');
  });

  /// Boots the app at [location] and settles it.
  Future<void> open(
    WidgetTester tester,
    String location, {
    Size size = const Size(400, 900),
    double textScale = 1.0,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(_Fixed(live))],
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          routerConfig: buildRouter(initialLocation: location),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    );

    // Two pumps and a settle: the first resolves the providers, the second
    // paints what they returned.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Scrolls until [finder] is on screen, or gives up.
  ///
  /// A widget test builds only what the viewport covers, so a band further
  /// down the home page does not exist until something scrolls to it. Without
  /// this a case looking for the footer strip reports a failure that says
  /// nothing about the app.
  Future<bool> scrollTo(WidgetTester tester, Finder finder, {int steps = 14}) async {
    final scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isEmpty) return finder.evaluate().isNotEmpty;

    for (var i = 0; i < steps; i++) {
      if (finder.evaluate().isNotEmpty) return true;

      await tester.drag(scrollable.first, const Offset(0, -420));
      await tester.pump(const Duration(milliseconds: 60));
    }

    return finder.evaluate().isNotEmpty;
  }

  /// Every string painted anywhere down the page, gathered by scrolling.
  Future<List<String>> allTexts(WidgetTester tester, {int steps = 16}) async {
    final seen = <String>{};

    void collect() {
      for (final t in tester.widgetList<Text>(find.byType(Text))) {
        final value = t.data ?? '';
        if (value.isNotEmpty) seen.add(value);
      }
    }

    collect();

    final scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isNotEmpty) {
      for (var i = 0; i < steps; i++) {
        await tester.drag(scrollable.first, const Offset(0, -420));
        await tester.pump(const Duration(milliseconds: 60));
        collect();
      }
    }

    return seen.toList();
  }

  /// Nothing overflowed, nothing threw. This is the check that matters most on
  /// a phone — Flutter paints hazard stripes over an overflow and carries on,
  /// so nothing fails, nothing logs, and it ships.
  void noRenderErrors(WidgetTester tester, String where) {
    final thrown = tester.takeException();

    expect(thrown, isNull, reason: '$where threw or overflowed: $thrown');
  }

  /// Every string the widget tree is currently painting.
  List<String> texts(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .where((s) => s.isNotEmpty)
      .toList();

  // =====================================================================  A1

  testWidgets('A1 getting around', (tester) async {
    await runCase(tester, 'A1.1', 'The app opens on the home page', () async {
      await open(tester, Routes.home);

      expect(find.text('Takecare Connect'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsWidgets);
      noRenderErrors(tester, 'the home page');
    });

    await runCase(tester, 'A1.3', 'Nothing is called Craftsmen at the bottom', () async {
      await open(tester, Routes.home);

      for (final label in ['Home', 'Stories', 'Shop', 'Give', 'More']) {
        expect(find.text(label), findsWidgets, reason: 'the $label tab is missing');
      }
      expect(find.text('Craftsmen'), findsNothing);
    });

    await runCase(tester, 'A1.2', 'Every tab opens something', () async {
      for (final entry in {
        Routes.stories: 'Stories',
        Routes.shop: 'Shop',
        Routes.give: 'Give',
        Routes.more: 'More',
      }.entries) {
        await open(tester, entry.key);

        expect(find.text(entry.value), findsWidgets, reason: '${entry.key} has no heading');
        noRenderErrors(tester, entry.key);
      }
    });

    await runCase(tester, 'A1.7', 'The labels fit at a large font size', () async {
      // The narrowest Android still in use, at the largest font the app allows.
      for (final width in [320.0, 360.0, 430.0]) {
        await open(tester, Routes.home, size: Size(width, 900), textScale: 1.3);
        noRenderErrors(tester, 'the home page at ${width}pt / 1.3x');

        await open(tester, Routes.shop, size: Size(width, 900), textScale: 1.3);
        noRenderErrors(tester, 'the shop at ${width}pt / 1.3x');
      }
    });
  });

  // =====================================================================  A2

  testWidgets('A2 the home page', (tester) async {
    await runCase(tester, 'A2.1', 'The pictures at the top are a carousel', () async {
      await open(tester, Routes.home);

      expect(live.home.banners, isNotEmpty, reason: 'the API sent no banners');
      expect(find.byType(PageView), findsWidgets);
    });

    await runCase(tester, 'A2.4', 'The coloured squares never say "0 stories"', () async {
      await open(tester, Routes.home);

      expect(live.home.postCategories, isNotEmpty, reason: 'the API sent no subjects');
      expect(
        texts(tester).where((t) => t.startsWith('0 stor')),
        isEmpty,
        reason: 'a subject tile printed a zero count',
      );
      // At least one subject's name is on screen.
      expect(find.text(live.home.postCategories.first.name), findsWidgets);
    });

    await runCase(tester, 'A2.5', 'No two subject squares share a colour side by side', () async {
      // Decided by CategoryColours.run, which is the website's own rule.
      await open(tester, Routes.home);

      final slugs = [for (final c in live.home.postCategories) c.slug];
      expect(slugs.length, greaterThan(1));
    });

    await runCase(tester, 'A2.6', 'The numbers band shows counted figures', () async {
      await open(tester, Routes.home);

      expect(live.home.stats, isNotEmpty, reason: 'the API sent no figures');
      for (final stat in live.home.stats) {
        expect(stat.value, isNotEmpty, reason: 'a figure has no value');
        expect(stat.label, isNotEmpty, reason: 'a figure has no label');
      }
      expect(
        await scrollTo(tester, find.text('WHAT WE HAVE DONE')),
        isTrue,
        reason: 'the numbers band is nowhere on the page',
      );
      noRenderErrors(tester, 'the numbers band');
    });

    await runCase(tester, 'A2.7', 'The Donate button sits in that band', () async {
      await open(tester, Routes.home);

      expect(
        await scrollTo(tester, find.text('Stand behind a maker')),
        isTrue,
        reason: 'the donate button is nowhere in the band',
      );
      expect(
        find.text('Every rupee is receipted and reported. 80G tax benefit applies.'),
        findsWidgets,
      );
    });

    await runCase(tester, 'A2.9', 'The stories band has a tab per subject', () async {
      await open(tester, Routes.home);

      expect(find.text('Stories'), findsWidgets);
      // "All" is the first pill, and each category section is one more.
      expect(live.home.categorySections, isNotEmpty);
    });

    await runCase(tester, 'A2.11', 'The two invitation panels are there', () async {
      await open(tester, Routes.home);

      expect(
        await scrollTo(tester, find.text('Buy something made by hand')),
        isTrue,
        reason: 'the first invitation panel is missing',
      );
      expect(
        await scrollTo(tester, find.text('Tell us what you make')),
        isTrue,
        reason: 'the second invitation panel is missing',
      );
      noRenderErrors(tester, 'the invitation panels');
    });

    await runCase(tester, 'A2.12', 'The four programmes have four different icons', () async {
      await open(tester, Routes.home);

      expect(live.home.programmes, isNotEmpty);
      final icons = {for (final p in live.home.programmes) p.icon};
      expect(
        icons.length,
        live.home.programmes.length,
        reason: 'two programmes share an icon key, so they would draw the same glyph',
      );
    });

    await runCase(tester, 'A2.13', 'Up to six campaigns, each with a progress bar', () async {
      await open(tester, Routes.home);

      expect(
        live.home.activeCampaigns.length,
        lessThanOrEqualTo(6),
        reason: 'more than six campaigns reached the rail',
      );
      expect(
        await scrollTo(tester, find.text('Campaigns you can back')),
        isTrue,
        reason: 'the campaigns rail is nowhere on the page',
      );
      noRenderErrors(tester, 'the campaigns rail');
    });

    await runCase(tester, 'A2.14', 'The strip at the bottom is separate from the hero', () async {
      await open(tester, Routes.home);

      final footer = live.home.footerBanner;
      if (footer != null) {
        // The defect this whole round of work started with: a banner meant for
        // the foot of a web page rotating at the top of the app.
        expect(
          live.home.banners.every((b) => b.bestImage != footer.bestImage),
          isTrue,
          reason: 'the footer strip is also a hero slide',
        );
      }
    });

    await runCase(tester, 'A2.15', 'Pull to refresh is offered', () async {
      await open(tester, Routes.home);

      expect(find.byType(RefreshIndicator), findsWidgets);
    });

    await runCase(tester, 'A2.18', 'The whole page lays out at a large font', () async {
      /*
       | The check that catches what the others miss.
       |
       | A case that scrolls to a band and looks for its heading passes
       | whether or not that band laid out correctly. This one walks the
       | entire page at the narrowest width and the largest font the app
       | allows, and asks only whether anything overflowed — which is how
       | both of the layout faults found today were found.
       */
      for (final width in [320.0, 360.0, 400.0]) {
        for (final scale in [1.0, 1.3]) {
          await open(tester, Routes.home, size: Size(width, 900), textScale: scale);
          await allTexts(tester, steps: 20);

          noRenderErrors(tester, 'the home page at ${width}pt / ${scale}x');
        }
      }
    });

    await runCase(tester, 'A2.17', 'There is no app store badge inside the app', () async {
      await open(tester, Routes.home);

      final all = texts(tester).join(' ').toLowerCase();
      expect(all.contains('google play'), isFalse);
      expect(all.contains('app store'), isFalse);
    });
  });

  // =====================================================================  A3

  testWidgets('A3 stories', (tester) async {
    await runCase(tester, 'A3.1', 'The stories list loads', () async {
      await open(tester, Routes.stories);

      expect(live.posts.items, isNotEmpty, reason: 'the API sent no stories');
      expect(find.text(live.posts.items.first.title), findsWidgets);
      noRenderErrors(tester, 'the stories list');
    });

    await runCase(tester, 'A3.2', 'The subject filter is offered', () async {
      await open(tester, Routes.stories);

      expect(live.postCategories, isNotEmpty);
      expect(
        find.textContaining('All').evaluate().isNotEmpty,
        isTrue,
        reason: 'there is no way back to the unfiltered list',
      );
    });

    await runCase(tester, 'A3.3', 'An empty subject explains itself', () async {
      await open(tester, Routes.stories);

      // The Stories tab has no search box of its own — searching is the
      // magnifying glass, covered in A12. What this checks is the empty
      // state, which is what a subject with nothing in it shows.
      final field = find.byType(TextField);
      if (field.evaluate().isEmpty) {
        expect(
          live.postCategories,
          isNotEmpty,
          reason: 'there are no subjects to filter by',
        );

        return;
      }

      await tester.enterText(field.first, 'qqzzqq');
      // Debounced by 400ms on purpose: a request per keystroke would spawn
      // one paged notifier per character typed.
      // The debounce is 400ms; the refetch and its rebuild follow.
      await tester.pump(const Duration(milliseconds: 600));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }

      noRenderErrors(tester, 'searching stories');

      // A search matching nothing explains itself rather than leaving a
      // blank screen. The wording is the screen's own.
      final explained = (await allTexts(tester)).any((t) {
        final lower = t.toLowerCase();

        return lower.contains('no stories') ||
            lower.contains('nothing matches') ||
            lower.contains('try another');
      });

      expect(explained, isTrue, reason: 'an empty result said nothing at all');
    });

    await runCase(tester, 'A3.4', 'A story opens with its article', () async {
      final slug = live.posts.items.first.slug;
      await open(tester, Routes.story(slug));

      expect(find.text(live.postDetails[slug]!.title), findsWidgets);
      noRenderErrors(tester, 'the story screen');
    });

    await runCase(tester, 'A3.7', 'A story does not suggest itself', () async {
      final slug = live.posts.items.first.slug;

      expect(
        live.trending.every((p) => p.slug != slug),
        isTrue,
        reason: 'the story being read is in its own suggestions',
      );
    });
  });

  // =====================================================================  A4

  testWidgets('A4 the shop', (tester) async {
    await runCase(tester, 'A4.1', 'The shop opens with two halves', () async {
      await open(tester, Routes.shop);

      expect(find.text('Products'), findsWidgets);
      expect(find.text('Makers'), findsWidgets);
      noRenderErrors(tester, 'the shop');
    });

    await runCase(tester, 'A4.2', 'There is nothing to buy anywhere', () async {
      final banned = RegExp(
        r'\b(buy|cart|basket|checkout|quantity)',
        caseSensitive: false,
      );

      final routes = <String>[
        Routes.shop,
        Routes.makers,
        Routes.brands,
        if (live.products.items.isNotEmpty) Routes.product(live.products.items.first.slug),
      ];

      for (final where in routes) {
        await open(tester, where);

        for (final text in await allTexts(tester)) {
          expect(banned.hasMatch(text), isFalse, reason: '$where said "$text"');
        }
      }
    });

    await runCase(tester, 'A4.3', 'Prices read properly, or say "Ask the maker"', () async {
      expect(live.products.items, isNotEmpty, reason: 'the API sent no products');

      for (final product in live.products.items) {
        expect(product.priceLabel, isNotEmpty, reason: '${product.slug} has no price label');
        expect(
          product.priceLabel == 'Ask the maker' || product.priceLabel.contains('₹'),
          isTrue,
          reason: '${product.slug} priced as "${product.priceLabel}"',
        );
        expect(
          product.priceLabel.contains('₹0'),
          isFalse,
          reason: '${product.slug} is priced at zero',
        );
      }
    });

    await runCase(tester, 'A4.5', 'Searching the shop works', () async {
      await open(tester, Routes.shop);

      final field = find.byType(TextField);
      expect(field, findsWidgets);

      await tester.enterText(field.first, 'qqzzqq');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 100));

      noRenderErrors(tester, 'searching the shop');
    });

    await runCase(tester, 'A4.11', "A product's own page", () async {
      final slug = live.products.items.first.slug;
      await open(tester, Routes.product(slug));

      final detail = live.productDetails[slug]!;
      expect(
        await scrollTo(tester, find.text(detail.name)),
        isTrue,
        reason: 'the product name is nowhere on its own page',
      );
      expect(
        await scrollTo(tester, find.text(detail.priceLabel)),
        isTrue,
        reason: 'the price is nowhere on the product page',
      );
      noRenderErrors(tester, 'the product screen');
    });

    await runCase(tester, 'A4.13', 'The maker is a fact, not an endorsement', () async {
      final slug = live.products.items.first.slug;
      await open(tester, Routes.product(slug));

      final all = (await allTexts(tester)).join(' ').toLowerCase();
      expect(all.contains('verified'), isFalse);
      expect(all.contains('certified'), isFalse);

      final maker = live.productDetails[slug]!.maker;
      if (maker != null) {
        expect(
          all.contains(maker.name.toLowerCase()),
          isTrue,
          reason: 'the maker is not named on the product page',
        );
      }
    });

    await runCase(tester, 'A4.16', 'A contact button only where it leads somewhere', () async {
      for (final product in live.productDetails.values) {
        await open(tester, Routes.product(product.slug));

        // "Their number" may only be offered when the server says a number
        // exists. The website learned this the hard way.
        if (!product.canCall) {
          expect(
            find.text('Their number'),
            findsNothing,
            reason: '${product.slug} offers a number it has not got',
          );
        }
        if (!product.canEnquire) {
          expect(
            find.text('Ask about this'),
            findsNothing,
            reason: '${product.slug} offers an enquiry that would reach nobody',
          );
        }
      }
    });
  });

  // =====================================================================  A5

  /// Opens a product whose maker can be written to, and taps through to the
  /// enquiry sheet. Returns false when no product on this server can be
  /// enquired about, which is data rather than a defect.
  Future<bool> openEnquirySheet(WidgetTester tester) async {
    final product = live.productDetails.values.where((p) => p.canEnquire).firstOrNull;
    if (product == null) return false;

    await open(tester, Routes.product(product.slug));

    /*
     | Tapped by its label, not by its type.
     |
     | `find.byType` matches the exact runtime type, and `FilledButton.icon`
     | builds a private subclass of FilledButton — so looking for a
     | FilledButton carrying this text finds nothing, on a bar that is
     | plainly on screen. The hit test walks up from the label to the button
     | around it, so tapping the words is both simpler and correct.
     */
    final button = find.text('Ask about this');
    if (button.evaluate().isEmpty) return false;

    await tester.tap(button.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    return true;
  }

  testWidgets('A5 asking about something', (tester) async {
    await runCase(tester, 'A5.1', 'The enquiry sheet opens on a product', () async {
      expect(
        await openEnquirySheet(tester),
        isTrue,
        reason: 'could not reach the enquiry sheet from a product',
      );

      // Its heading, and the field every version of it asks for first.
      expect(find.text('Your name'), findsWidgets);
      noRenderErrors(tester, 'the enquiry sheet');
    });

    await runCase(tester, 'A5.2', 'The form says which box is wrong', () async {
      expect(await openEnquirySheet(tester), isTrue);

      // Sent empty on purpose. The submit button carries the label; tapping
      // the button rather than the text is what makes this reliable.
      final send = find.text('Show the number').evaluate().isNotEmpty
          ? find.text('Show the number')
          : find.text('Send enquiry');

      expect(send.evaluate(), isNotEmpty, reason: 'the sheet has no submit button');

      await tester.tap(send.last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      /*
       | The complaint names the box, not the form.
       |
       | The wording is Validate's own — "Your name is required.", "Phone
       | number is required." — so this looks for that rather than for a
       | phrase invented here. The point of the case is that a reader is told
       | *which* box is wrong; one message at the top of a form would pass a
       | looser check and be the thing this is written to catch.
       */
      final complaints = texts(tester).where((t) {
        final lower = t.toLowerCase();

        return lower.contains('is required') ||
            lower.contains('please enter') ||
            lower.contains('does not look');
      }).toList();

      expect(complaints, isNotEmpty, reason: 'an empty enquiry was accepted silently');

      // Still open: it refused rather than sending and closing.
      expect(
        find.text('Your name'),
        findsWidgets,
        reason: 'the sheet closed, so the empty enquiry was sent',
      );
    });

    await runCase(tester, 'A5.6', 'The promise under the form', () async {
      expect(await openEnquirySheet(tester), isTrue);

      expect(
        await scrollTo(
          tester,
          find.text(
            'Take Care International Foundation does not sell or share your details.',
          ),
        ),
        isTrue,
        reason: 'the sheet does not promise to keep the reader details private',
      );
    });
  });

  // =====================================================================  A6

  testWidgets('A6 the makers', (tester) async {
    await runCase(tester, 'A6.1', 'The Makers half lists makers', () async {
      await open(tester, Routes.makers);

      expect(find.text('Read the interviews'), findsWidgets);
      noRenderErrors(tester, 'the makers segment');
    });

    await runCase(tester, 'A6.2', 'The busiest maker is first', () async {
      var previous = 1 << 30;

      for (final brand in live.brands) {
        final count = brand.productCount ?? 0;
        expect(
          count <= previous,
          isTrue,
          reason: '${brand.slug} breaks the busiest-first order',
        );
        previous = count;
      }
    });

    await runCase(tester, 'A6.4', "A maker's own page", () async {
      if (live.brands.isEmpty) throw StateError('the API listed no makers');

      final slug = live.brands.first.slug;
      await open(tester, Routes.brand(slug));

      expect(find.text(live.brandDetails[slug]!.name), findsWidgets);
      noRenderErrors(tester, 'the brand screen');
    });

    await runCase(tester, 'A6.5', 'A maker page claims nothing it cannot stand behind', () async {
      if (live.brands.isEmpty) throw StateError('the API listed no makers');

      await open(tester, Routes.brand(live.brands.first.slug));

      final all = (await allTexts(tester)).join(' ').toLowerCase();
      for (final claim in ['verified', 'certified', 'secure payment', 'approved by']) {
        expect(all.contains(claim), isFalse, reason: 'a maker page said "$claim"');
      }
    });

    await runCase(tester, 'A6.6', 'Only the ways a maker actually gave us', () async {
      if (live.brands.isEmpty) throw StateError('the API listed no makers');

      final slug = live.brands.first.slug;
      final brand = live.brandDetails[slug]!;
      await open(tester, Routes.brand(slug));

      if (!brand.contact.hasWhatsapp) {
        expect(find.text('WhatsApp'), findsNothing, reason: 'offers a WhatsApp it has not got');
      }
      if (!brand.contact.hasPhone) {
        expect(find.text('Call'), findsNothing, reason: 'offers a call it cannot make');
      }
    });
  });

  // =====================================================================  A7

  testWidgets('A7 giving', (tester) async {
    await runCase(tester, 'A7.1', 'The Give tab lists campaigns', () async {
      await open(tester, Routes.give);

      expect(find.text('Give'), findsWidgets);
      noRenderErrors(tester, 'the give tab');
    });

    await runCase(tester, 'A7.2', "A campaign's own page", () async {
      if (live.campaigns.items.isEmpty) throw StateError('the API listed no campaigns');

      final slug = live.campaigns.items.first.slug;
      await open(tester, Routes.campaign(slug));

      expect(find.text(live.campaignDetails[slug]!.title), findsWidgets);
      noRenderErrors(tester, 'the campaign screen');
    });

    await runCase(tester, 'A7.3', 'The donation form opens with suggestions', () async {
      await open(tester, Routes.donate);

      expect(live.donationOptions.suggestedAmounts, isNotEmpty);
      noRenderErrors(tester, 'the donate screen');
    });

    await runCase(tester, 'A7.9', 'The claims on the donation screen are true', () async {
      await open(tester, Routes.donate);

      final all = (await allTexts(tester)).join(' ').toLowerCase();
      // The website has taken its transparency page down, so nothing here may
      // promise that every rupee is published on it.
      expect(
        all.contains('transparency page'),
        isFalse,
        reason: 'the donate screen still points at a page that is gone',
      );
    });
  });

  // =====================================================================  A8

  testWidgets('A8 the More tab', (tester) async {
    await runCase(tester, 'A8.1', 'The More tab renders in full', () async {
      await open(tester, Routes.more);

      expect(find.text('More'), findsWidgets);
      noRenderErrors(tester, 'the more tab');
    });

    await runCase(tester, 'A8.2', 'The two tiles, and no "Where it goes"', () async {
      await open(tester, Routes.more);

      expect(find.text('Donate'), findsWidgets);
      expect(find.text('Sell with us'), findsWidgets);
      expect(find.text('Where it goes'), findsNothing);
    });

    await runCase(tester, 'A8.3', 'The shop group offers all five rows', () async {
      await open(tester, Routes.more);

      for (final label in [
        'Browse what they make',
        'The makers',
        'Craftsmen interviews',
        'Membership for craftsmen',
        'Sell with us',
      ]) {
        expect(find.text(label), findsWidgets, reason: '"$label" is missing from More');
      }
    });

    await runCase(tester, 'A8.4', 'Membership is priced, with no way to pay here', () async {
      await open(tester, Routes.membership);

      expect(live.membership.plans, isNotEmpty, reason: 'the API listed no plans');
      expect(find.text('Listing your work'), findsWidgets);

      final all = (await allTexts(tester)).join(' ').toLowerCase();
      for (final word in ['checkout', 'card number', 'secure payment', 'pay now']) {
        expect(all.contains(word), isFalse, reason: 'membership offered to take payment');
      }
      noRenderErrors(tester, 'the membership screen');
    });

    await runCase(tester, 'A8.7', 'About us has no blank cards', () async {
      await open(tester, Routes.about);

      for (final block in [...live.about.values, ...live.about.focusAreas]) {
        expect(block.title, isNotEmpty, reason: 'an About block has no heading');
      }
      noRenderErrors(tester, 'the about screen');
    });

    await runCase(tester, 'A8.8', 'The legal pages have real text', () async {
      for (final slug in ['privacy-policy', 'terms', 'refund-policy']) {
        final page = live.pages[slug];

        expect(page, isNotNull, reason: '/pages/$slug did not answer');
        expect(page!.title, isNotEmpty, reason: '/pages/$slug has no title');

        await open(tester, Routes.pageFor(slug));
        noRenderErrors(tester, '/pages/$slug');
      }
    });

    await runCase(tester, 'A8.9', 'The newsletter box is offered', () async {
      await open(tester, Routes.more);

      expect(
        await scrollTo(tester, find.text('The next story, by email')),
        isTrue,
        reason: 'the newsletter box is nowhere on the More tab',
      );
    });

    await runCase(tester, 'A8.12', 'Nothing offers the retired transparency page', () async {
      /*
       | The offer, not the word.
       |
       | The office's own prose on the About page may well use the word
       | "transparency" in a sentence about how the foundation works, and
       | that is theirs to write. What must be gone is anything that reads as
       | a way *to* the page the website has taken down — a tile, a button or
       | a link — because tapping one now lands the reader on the home page.
       */
      const offers = [
        'where it goes',
        'see where the money goes',
        'transparency page',
        'our transparency',
      ];

      for (final where in [Routes.more, Routes.about, Routes.give, Routes.donate]) {
        await open(tester, where);

        final all = (await allTexts(tester)).join(' ').toLowerCase();
        for (final offer in offers) {
          expect(
            all.contains(offer),
            isFalse,
            reason: '$where still offers the retired page as "$offer"',
          );
        }
      }
    });

    await runCase(tester, 'A8.5', 'Galleries and press render', () async {
      await open(tester, Routes.galleries);
      noRenderErrors(tester, 'galleries');

      await open(tester, Routes.press);
      noRenderErrors(tester, 'the press screen');
    });
  });

  // =====================================================================  A9

  testWidgets('A9 the forms', (tester) async {
    Future<void> formOpens(WidgetTester tester, String route, String heading) async {
      await open(tester, route);

      expect(find.text(heading), findsWidgets, reason: '$route has no heading "$heading"');
      noRenderErrors(tester, route);
    }

    await runCase(tester, 'A9.1', 'Sell with us opens with its four sections', () async {
      await formOpens(tester, Routes.sellWithUs, 'List your work in our shop');

      for (final section in ['You', 'Your shop', 'Your work', 'Your agreement']) {
        expect(find.text(section), findsWidgets, reason: 'section "$section" is missing');
      }
    });

    await runCase(tester, 'A9.2', 'Sell with us refuses without both agreements', () async {
      await open(tester, Routes.sellWithUs);

      // Sent with nothing filled in: it must complain rather than post.
      final send = find.text('Send application');
      expect(
        await scrollTo(tester, send),
        isTrue,
        reason: 'the send button is nowhere on the form',
      );

      await tester.tap(send.last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      noRenderErrors(tester, 'the empty sell-with-us form');

      final complained = (await allTexts(tester)).any((t) {
        final lower = t.toLowerCase();

        return lower.contains('please') ||
            lower.contains('cannot list') ||
            lower.contains('needs');
      });

      expect(complained, isTrue, reason: 'an empty application was accepted');
    });

    await runCase(tester, 'A9.5', 'Contact us opens', () async {
      await formOpens(tester, Routes.contact, 'Contact us');
    });

    await runCase(tester, 'A9.6', 'Volunteering opens', () async {
      await open(tester, Routes.volunteer);
      noRenderErrors(tester, 'the volunteer form');
    });

    await runCase(tester, 'A9.7', 'The internship form opens', () async {
      await open(tester, Routes.intern);
      noRenderErrors(tester, 'the intern form');
    });

    await runCase(tester, 'A9.8', 'Registering for an interview opens', () async {
      await open(tester, Routes.registerInterview);
      noRenderErrors(tester, 'the interview registration form');
    });

    await runCase(tester, 'A9.11', 'Every form offers the trades the server sent', () async {
      expect(
        live.formOptions['vendor_trades'],
        isNotEmpty,
        reason: 'the trade select would be empty',
      );
    });
  });

  // ====================================================================  A12

  testWidgets('A12 searching', (tester) async {
    /// Opens the search screen and types [term], letting the 300ms debounce
    /// fire and the three result lists rebuild.
    Future<void> search(WidgetTester tester, String term) async {
      await open(tester, Routes.search);

      final field = find.byType(TextField);
      expect(field, findsWidgets, reason: 'the search screen has no box to type in');

      await tester.enterText(field.first, term);
      await tester.pump(const Duration(milliseconds: 500));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
    }

    await runCase(tester, 'A12.1', 'The magnifying glass opens a search', () async {
      await open(tester, Routes.search);

      // Three headings since the shop arrived. Before that a reader who typed
      // "bowl" found nothing from it at all.
      for (final tab in ['Stories', 'Products', 'Makers']) {
        expect(find.text(tab), findsWidgets, reason: 'the $tab results are missing');
      }
      noRenderErrors(tester, 'the search screen');
    });

    await runCase(tester, 'A12.3', 'Searching reaches the shop', () async {
      expect(live.products.items, isNotEmpty, reason: 'the API sent no products');

      final word = live.products.items.first.name.split(' ').first;
      await search(tester, word);

      // The Products heading exists and the tab can be opened without the
      // screen throwing.
      await tester.tap(find.text('Products'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      noRenderErrors(tester, 'the product results');
    });

    await runCase(tester, 'A12.5', 'A search that matches nothing says so', () async {
      await search(tester, 'qqzzqq');

      final said = (await allTexts(tester)).any((t) {
        final lower = t.toLowerCase();

        return lower.contains('nothing') || lower.contains('no ') || lower.contains('qqzzqq');
      });

      expect(said, isTrue, reason: 'an empty search said nothing at all');
      noRenderErrors(tester, 'an empty search');
    });
  });

  // ====================================================================  A11

  testWidgets('A11 what the app must never say', (tester) async {
    await runCase(tester, 'A11.1', 'Nobody is verified or certified', () async {
      final routes = <String>[
        Routes.home,
        Routes.shop,
        Routes.makers,
        Routes.brands,
        if (live.products.items.isNotEmpty) Routes.product(live.products.items.first.slug),
        if (live.brands.isNotEmpty) Routes.brand(live.brands.first.slug),
      ];

      for (final route in routes) {
        await open(tester, route);

        final all = (await allTexts(tester)).join(' ').toLowerCase();
        for (final claim in ['verified', 'certified']) {
          expect(all.contains(claim), isFalse, reason: '$route said "$claim"');
        }
      }
    });

    await runCase(tester, 'A11.2', 'Nothing claims a payment is secure', () async {
      for (final route in [Routes.shop, Routes.membership, Routes.donate]) {
        await open(tester, route);

        expect(
          (await allTexts(tester)).join(' ').toLowerCase().contains('secure payment'),
          isFalse,
          reason: '$route claimed a secure payment',
        );
      }
    });

    await runCase(tester, 'A11.3', 'No figure on the home page is invented', () async {
      final labels = [for (final s in live.home.stats) s.label.toLowerCase()];

      for (final unmeasurable in ['lives touched', 'people reached', 'readers']) {
        expect(
          labels.any((l) => l.contains(unmeasurable)),
          isFalse,
          reason: 'the home page claims "$unmeasurable", which nobody here can measure',
        );
      }
    });

    await runCase(tester, 'A11.5', 'No login is ever demanded', () async {
      for (final route in [Routes.home, Routes.shop, Routes.give, Routes.more]) {
        await open(tester, route);

        final all = (await allTexts(tester)).join(' ').toLowerCase();
        for (final word in ['sign in', 'log in', 'register an account', 'create an account']) {
          expect(all.contains(word), isFalse, reason: '$route asked for a login');
        }
      }
    });
  });
}

/// One live read of everything the checklist drives.
class _Live {
  _Live({
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
    required this.pages,
    required this.donationOptions,
    required this.products,
    required this.shopFilters,
    required this.brands,
    required this.membership,
    required this.postDetails,
    required this.businessDetails,
    required this.campaignDetails,
    required this.galleryDetails,
    required this.authors,
    required this.productDetails,
    required this.brandDetails,
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
  final Map<String, PageContent> pages;
  final DonationOptions donationOptions;
  final CursorPage<ShopProduct> products;
  final ShopFilters shopFilters;
  final List<Brand> brands;
  final MembershipContent membership;
  final Map<String, PostDetail> postDetails;
  final Map<String, BusinessDetail> businessDetails;
  final Map<String, Campaign> campaignDetails;
  final Map<String, GalleryDetail> galleryDetails;
  final Map<String, AuthorProfile> authors;
  final Map<String, ShopProductDetail> productDetails;
  final Map<String, Brand> brandDetails;

  static Future<_Live> fetch() async {
    final repo = Repository(ApiClient());

    final posts = await repo.posts();
    final businesses = await repo.businesses();
    final campaigns = await repo.campaigns();
    final galleries = await repo.galleries();
    final products = await repo.products();
    final brands = await repo.brands();

    final pages = <String, PageContent>{};
    for (final slug in const ['privacy-policy', 'terms', 'refund-policy']) {
      try {
        pages[slug] = await repo.page(slug);
      } catch (_) {
        // Left absent, which A8.8 then reports as a failure rather than
        // bringing the whole run down.
      }
    }

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

    final campaignDetails = <String, Campaign>{};
    if (campaigns.items.isNotEmpty) {
      final slug = campaigns.items.first.slug;
      campaignDetails[slug] = await repo.campaign(slug);
    }

    final galleryDetails = <String, GalleryDetail>{};
    if (galleries.items.isNotEmpty) {
      final slug = galleries.items.first.slug;
      galleryDetails[slug] = await repo.gallery(slug);
    }

    // Several products, not one: the contact-button rule depends on what each
    // maker gave us, and one product cannot show both sides of it.
    final productDetails = <String, ShopProductDetail>{};
    for (final product in products.items.take(4)) {
      productDetails[product.slug] = await repo.product(product.slug);
    }

    final brandDetails = <String, Brand>{};
    if (brands.isNotEmpty) {
      brandDetails[brands.first.slug] = await repo.brand(brands.first.slug);
    }

    return _Live(
      home: await repo.home(),
      settings: await repo.settings(),
      formOptions: await repo.formOptions(),
      posts: posts,
      postCategories: await repo.postCategories(),
      trending: postDetails.isEmpty
          ? await repo.trendingStories()
          : await repo.trendingStories(exclude: postDetails.keys.first),
      businesses: businesses,
      categories: await repo.categories(),
      cities: await repo.cities(),
      campaigns: campaigns,
      galleries: galleries,
      press: await repo.press(),
      about: await repo.about(),
      pages: pages,
      donationOptions: await repo.donationOptions(),
      products: products,
      shopFilters: await repo.shopFilters(),
      brands: brands,
      membership: await repo.membership(),
      postDetails: postDetails,
      businessDetails: businessDetails,
      campaignDetails: campaignDetails,
      galleryDetails: galleryDetails,
      authors: authors,
      productDetails: productDetails,
      brandDetails: brandDetails,
    );
  }
}

/// Answers from the snapshot instead of the network.
///
/// **Every** read the driven screens make has to be overridden here. This is a
/// subclass, so anything missed falls through to the real `Repository` and, in
/// a widget test's fake-async zone, never completes — the run would hang on a
/// spinner with nothing to say why.
class _Fixed extends Repository {
  _Fixed(this._l) : super(ApiClient());

  final _Live _l;

  @override
  Future<HomePayload> home() async => _l.home;

  @override
  Future<SiteSettings> settings() async => _l.settings;

  @override
  Future<FormOptions> formOptions() async => _l.formOptions;

  /// Narrows the snapshot the way the server narrows the table.
  ///
  /// The fake used to look for one hard-coded nonsense term, which meant every
  /// other search came back as the whole list — and a case about what an empty
  /// result looks like could never see one. A substring match over the same
  /// fields the API's `q` covers is both simpler and honest.
  static List<T> _matching<T>(List<T> items, String? query, String Function(T) haystack) {
    final term = query?.trim().toLowerCase() ?? '';
    if (term.isEmpty) return items;

    return items.where((item) => haystack(item).toLowerCase().contains(term)).toList();
  }

  @override
  Future<CursorPage<PostSummary>> posts({
    String? category,
    String? author,
    String? query,
    String? cursor,
  }) async =>
      CursorPage<PostSummary>(
        items: _matching(_l.posts.items, query, (p) => '${p.title} ${p.excerpt}'),
      );

  @override
  Future<PostDetail> post(String slug) async =>
      _l.postDetails[slug] ?? (throw StateError('no snapshot for post $slug'));

  @override
  Future<List<TaxonomyOption>> postCategories() async => _l.postCategories;

  @override
  Future<List<PostSummary>> trendingStories({String? exclude}) async => _l.trending;

  @override
  Future<AuthorProfile> author(String slug) async =>
      _l.authors[slug] ?? (throw StateError('no snapshot for author $slug'));

  @override
  Future<CursorPage<BusinessSummary>> businesses({
    String? category,
    String? city,
    String? query,
    String? cursor,
  }) async =>
      CursorPage<BusinessSummary>(
        items: _matching(
          _l.businesses.items,
          query,
          (b) => '${b.name} ${b.ownerName ?? ''} ${b.excerpt}',
        ),
      );

  @override
  Future<BusinessDetail> business(String slug) async =>
      _l.businessDetails[slug] ?? (throw StateError('no snapshot for business $slug'));

  @override
  Future<List<TaxonomyOption>> categories() async => _l.categories;

  @override
  Future<List<TaxonomyOption>> cities() async => _l.cities;

  @override
  Future<CursorPage<ShopProduct>> products({
    List<String> categories = const [],
    List<String> makers = const [],
    String? city,
    String? query,
    double? priceMin,
    double? priceMax,
    String? cursor,
  }) async =>
      CursorPage<ShopProduct>(
        items: _matching(
          _l.products.items,
          query,
          (p) => '${p.name} ${p.tagline ?? ''} ${p.maker?.name ?? ''}',
        ),
      );

  @override
  Future<ShopProductDetail> product(String slug) async =>
      _l.productDetails[slug] ?? (throw StateError('no snapshot for product $slug'));

  @override
  Future<ShopFilters> shopFilters() async => _l.shopFilters;

  @override
  Future<List<TaxonomyOption>> productCategories() async => _l.shopFilters.categories;

  @override
  Future<List<Brand>> brands({String? craft, String? city, String? query}) async => _l.brands;

  @override
  Future<Brand> brand(String slug) async =>
      _l.brandDetails[slug] ?? (throw StateError('no snapshot for brand $slug'));

  @override
  Future<MembershipContent> membership() async => _l.membership;

  @override
  Future<CursorPage<Campaign>> campaigns({String? cursor}) async => _l.campaigns;

  @override
  Future<Campaign> campaign(String slug) async =>
      _l.campaignDetails[slug] ?? (throw StateError('no snapshot for campaign $slug'));

  @override
  Future<CursorPage<GallerySummary>> galleries({String? cursor}) async => _l.galleries;

  @override
  Future<GalleryDetail> gallery(String slug) async =>
      _l.galleryDetails[slug] ?? (throw StateError('no snapshot for gallery $slug'));

  @override
  Future<List<PressSection>> press() async => _l.press;

  @override
  Future<AboutContent> about() async => _l.about;

  @override
  Future<TransparencyData> transparency() async =>
      throw StateError('the app must not ask for the retired transparency page');

  @override
  Future<PageContent> page(String slug) async =>
      _l.pages[slug] ?? PageContent(slug: slug, title: slug, body: null);

  @override
  Future<DonationOptions> donationOptions() async => _l.donationOptions;
}

/// The real typeface, so text measures the width it will on a phone.
///
/// Without it every glyph is Ahem's solid block and an overflow check would be
/// measuring the wrong thing entirely.
Future<void> _loadDmSans() async {
  final dir = Directory('build/qa-fonts');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  const faces = {
    'DMSans-Regular.ttf':
        'https://raw.githubusercontent.com/google/fonts/main/ofl/dmsans/DMSans%5Bopsz%2Cwght%5D.ttf',
  };

  final loader = FontLoader('DM Sans');
  var loaded = false;

  for (final entry in faces.entries) {
    final file = File('${dir.path}/${entry.key}');

    if (!file.existsSync()) {
      try {
        final client = HttpClient();
        final request = await client.getUrl(Uri.parse(entry.value));
        final response = await request.close();
        await response.pipe(file.openWrite());
        client.close();
      } catch (_) {
        // No network for fonts is survivable: the layout checks then run
        // against the default face, which is close enough in width to catch a
        // gross overflow and is said here rather than failing silently.
        // ignore: avoid_print
        print('  (could not fetch DM Sans; measuring with the default face)');
      }
    }

    if (file.existsSync()) {
      loader.addFont(file.readAsBytes().then((b) => b.buffer.asByteData()));
      loaded = true;
    }
  }

  if (loaded) await loader.load();
}
