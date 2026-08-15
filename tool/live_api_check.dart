import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takecare_connect/core/api/api_client.dart';
import 'package:takecare_connect/core/api/api_endpoints.dart';
import 'package:takecare_connect/core/api/repository.dart';

/// Parses every endpoint's **live** response through the real models.
///
/// ```
/// flutter test tool/live_api_check.dart
/// ```
///
/// Not part of `flutter test`'s normal run: it needs the network and it talks
/// to production, so a failure here means the server changed rather than the
/// app broke. It lives in tool/ so CI never picks it up.
///
/// Worth having anyway, because it is the only thing that catches the class of
/// bug the unit tests cannot: a field the API renamed, a null where the model
/// expected a string, a list that arrived as an object. Every model in this app
/// is hand-written with defensive defaults, which means a mismatch does not
/// throw — it quietly renders an empty screen. This asserts on the *contents*,
/// not just that parsing completed.
void main() {
  late Repository repo;

  setUpAll(() {
    // ApiClient stamps every request with an X-Client-Id it reads from
    // shared_preferences, which is a platform channel. Without a binding and a
    // mock store that throws inside the dio interceptor — and dio reports an
    // interceptor throw as a transport failure, so the whole suite fails with
    // "Could not reach Take Care International" and not one request is made.
    TestWidgetsFlutterBinding.ensureInitialized();
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});

    // …and then undo what that binding did to networking. It installs an
    // HttpOverrides that answers every request with a 400 and never opens a
    // socket, which is right for a widget test and exactly wrong for this
    // file. Clearing it restores the real client.
    HttpOverrides.global = null;

    repo = Repository(ApiClient());
    // ignore: avoid_print
    print('checking ${Api.base}');
  });

  test('home composes the whole front page', () async {
    final home = await repo.home();

    expect(
      home.banners.isNotEmpty ||
          home.featuredStories.isNotEmpty ||
          home.featuredCraftsmen.isNotEmpty,
      isTrue,
      reason: 'the home payload is entirely empty',
    );

    for (final post in home.featuredStories) {
      expect(post.slug, isNotEmpty);
      expect(post.title, isNotEmpty);
    }

    for (final banner in home.banners) {
      // Either it carries artwork or it carries words. A banner with neither
      // renders as a blank 4:3 hole at the top of the app.
      expect(
        banner.bestImage != null || (banner.title?.isNotEmpty ?? false),
        isTrue,
        reason: 'a banner has no image and no title',
      );
    }

    // ignore: avoid_print
    print('  home: ${home.banners.length} banners, '
        '${home.featuredStories.length} stories, '
        '${home.featuredCraftsmen.length} craftsmen, '
        '${home.activeCampaigns.length} campaigns, '
        '${home.categorySections.length} rails');
  });

  test('settings carry the footer and the credentials', () async {
    final settings = await repo.settings();

    expect(settings.name, isNotEmpty);
    // These are what tell a donor this is a registered organisation, and the
    // donate screen prints them above the submit button.
    expect(settings.credentials, isNotEmpty);

    // ignore: avoid_print
    print('  settings: ${settings.name} — ${settings.credentials.join(", ")}');
  });

  test('form options cover every select the forms render', () async {
    final options = await repo.formOptions();

    for (final key in const [
      'contact_subjects',
      'enquiry_intents',
      'volunteer_areas',
      'intern_areas',
      'modes',
      'hours_per_week',
      'durations',
      'years_of_study',
      'how_heard',
      'team_sizes',
      'turnover_bands',
    ]) {
      expect(options[key], isNotEmpty, reason: '$key is missing or empty');

      for (final option in options[key]) {
        expect(option.value, isNotEmpty);
        expect(option.label, isNotEmpty);
      }
    }
  });

  test('stories paginate and open', () async {
    final page = await repo.posts();

    expect(page.items, isNotEmpty);
    expect(page.nextCursor, isNotNull, reason: 'only one page of stories?');

    final detail = await repo.post(page.items.first.slug);
    expect(detail.title, isNotEmpty);
    expect(detail.body, isNotNull);

    // The server strips the duplicate opening image; if that regressed, the
    // hero would appear twice in every article.
    if (detail.image != null && detail.body != null) {
      expect(
        detail.body!.contains(detail.image!),
        isFalse,
        reason: 'the hero image is repeated inside the body',
      );
    }

    final second = await repo.posts(cursor: page.nextCursor);
    expect(second.items, isNotEmpty);

    final firstSlugs = page.items.map((p) => p.slug).toSet();
    expect(
      second.items.every((p) => !firstSlugs.contains(p.slug)),
      isTrue,
      reason: 'page two repeats page one',
    );

    // ignore: avoid_print
    print('  stories: "${detail.title}" (${detail.readingMinutes} min)');
  });

  test('craftsmen carry their products', () async {
    final page = await repo.businesses();
    expect(page.items, isNotEmpty);

    var withProducts = 0;
    var checked = 0;

    for (final summary in page.items.take(5)) {
      final business = await repo.business(summary.slug);

      expect(business.name, isNotEmpty);
      checked++;

      if (business.products.isNotEmpty) {
        withProducts++;

        for (final product in business.products) {
          expect(product.name, isNotEmpty);
        }
      }
    }

    expect(
      withProducts,
      greaterThan(0),
      reason: 'none of $checked craftsmen has a single product — the import broke',
    );

    // ignore: avoid_print
    print('  craftsmen: $withProducts of $checked have products');
  });

  test('taxonomies are populated', () async {
    final categories = await repo.categories();
    final cities = await repo.cities();
    final postCategories = await repo.postCategories();

    expect(categories, isNotEmpty);
    expect(cities, isNotEmpty);
    expect(postCategories, isNotEmpty);

    // ignore: avoid_print
    print('  taxonomies: ${categories.length} trades, ${cities.length} cities, '
        '${postCategories.length} blog categories');
  });

  test('campaigns report their progress', () async {
    final page = await repo.campaigns();

    for (final campaign in page.items) {
      expect(campaign.slug, isNotEmpty);
      expect(campaign.progressFraction, inInclusiveRange(0, 1));
    }

    if (page.items.isNotEmpty) {
      final detail = await repo.campaign(page.items.first.slug);
      expect(detail.title, isNotEmpty);
    }

    // ignore: avoid_print
    print('  campaigns: ${page.items.length}');
  });

  test('galleries and press parse', () async {
    final galleries = await repo.galleries();

    if (galleries.items.isNotEmpty) {
      final detail = await repo.gallery(galleries.items.first.slug);
      expect(detail.title, isNotEmpty);

      for (final photo in detail.photos) {
        expect(photo.url, isNotEmpty);
      }
    }

    final press = await repo.press();

    for (final section in press) {
      for (final item in section.items) {
        expect(item.title, isNotEmpty);
      }
    }

    // ignore: avoid_print
    print('  media: ${galleries.items.length} galleries, '
        '${press.fold<int>(0, (n, s) => n + s.items.length)} press items');
  });

  test('the content pages parse', () async {
    final about = await repo.about();

    expect(about.title, isNotEmpty);
    expect(about.vision, isNotEmpty);
    expect(about.mission, isNotEmpty);
    expect(about.values, isNotEmpty);

    // This one is worth asserting rather than printing. The key is `focusAreas`
    // — camelCase, alone among snake_case siblings, because the block is spread
    // from the website's Inertia props. Reading `focus_areas` parses fine and
    // silently yields an empty section.
    expect(about.focusAreas, isNotEmpty, reason: 'the focus areas key changed');

    for (final block in [...about.values, ...about.focusAreas]) {
      // A focus area carries `label` and a value carries `title`; a block with
      // neither renders as a blank card.
      expect(block.title, isNotEmpty, reason: 'a block has no heading');
    }

    for (final stat in about.stats) {
      expect(stat.value, isNotEmpty);
      expect(stat.label, isNotEmpty);
    }

    final transparency = await repo.transparency();
    expect(transparency.title, isNotEmpty);

    // ignore: avoid_print
    print('  about: ${about.values.length} values, ${about.focusAreas.length} focus areas, '
        '${about.stats.length} stats');
    // ignore: avoid_print
    print('  transparency: ${transparency.campaigns.length} campaigns listed');
  });

  test('the static pages the More tab links to actually exist', () async {
    // Hard-coded in more_screen.dart, and the slugs are not what the titles
    // suggest — "Terms of use" lives at `terms`. A 404 here is a dead row in
    // the menu, which nothing else in the project would catch.
    for (final slug in const [
      'team',
      'annual-reports',
      'privacy-policy',
      'terms',
      'refund-policy',
    ]) {
      final page = await repo.page(slug);

      expect(page.title, isNotEmpty, reason: '/pages/$slug is empty');
    }
  });

  test('donation options describe the form', () async {
    final options = await repo.donationOptions();

    expect(options.currencies, isNotEmpty);
    expect(options.suggestedAmounts, isNotEmpty);

    // ignore: avoid_print
    print('  donations: open=${options.donationsOpen}, '
        'currencies=${options.currencies.join("/")}, '
        'PAN above ${options.panThreshold}');
  });
}
