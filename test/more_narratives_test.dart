import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takecare_connect/core/models/post.dart';
import 'package:takecare_connect/core/models/site.dart';
import 'package:takecare_connect/core/state/providers.dart';
import 'package:takecare_connect/core/theme/app_theme.dart';
import 'package:takecare_connect/features/more/more_screen.dart';

/// The Influencing Narratives group on the More screen.
///
/// It is the website's own menu of story categories, and it is read from
/// `/post-categories` rather than written out in the app: the six on the site
/// are a list the office edits, and an installed copy cannot be updated to
/// follow a rename.
///
/// The live six at the time of writing, in the order the endpoint returns them
/// — it orders by name, which is not the curated order the website's dropdown
/// uses.
void main() {
  const categories = <TaxonomyOption>[
    TaxonomyOption(slug: 'ai-stories', name: 'AI Stories'),
    TaxonomyOption(slug: 'education-stories', name: 'Education stories'),
    TaxonomyOption(slug: 'enterprise-stories', name: 'Enterprise stories'),
    TaxonomyOption(slug: 'her-stories', name: 'Her stories'),
    TaxonomyOption(slug: 'social-stories', name: 'Social stories'),
    TaxonomyOption(slug: 'startup-stories', name: 'Startup stories'),
  ];

  Future<void> pump(
    WidgetTester tester,
    List<TaxonomyOption> options, {
    double width = 390,
    double scale = 1.0,
  }) async {
    // Tall enough that the whole menu builds. A ListView only builds what is
    // near the viewport, so at a phone's height the groups below the fold do
    // not exist to be found — and `skipOffstage: false` does not help, because
    // they were never created rather than merely hidden.
    await tester.binding.setSurfaceSize(Size(width, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postCategoriesProvider.overrideWith((ref) => options),
          // Left hanging rather than given a fixture: the screen reads it with
          // valueOrNull and draws its header either way, and letting the real
          // one run starts an HTTP request whose timeout outlives the test —
          // "a Timer is still pending after the widget tree was disposed".
          settingsProvider.overrideWith((ref) => Completer<SiteSettings>().future),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          builder: (context, inner) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: inner!,
          ),
          home: const MoreScreen(),
        ),
      ),
    );

    await tester.pump();
  }

  testWidgets('every category the server sends gets a row', (tester) async {
    await pump(tester, categories);

    // _Group uppercases its label.
    expect(find.text('INFLUENCING NARRATIVES'), findsOneWidget);

    for (final category in categories) {
      expect(
        find.text(category.name),
        findsOneWidget,
        reason: '${category.name} is missing from More',
      );
    }
  });

  /// A menu is scanned, not read. A spinner or an error row in the middle of
  /// one is worse than the group simply not being there — Stories is a tab of
  /// its own either way.
  testWidgets('nothing is drawn when there are no categories', (tester) async {
    await pump(tester, const []);

    expect(find.text('INFLUENCING NARRATIVES'), findsNothing);
  });

  /// The rest of the menu must not move or disappear because this group was
  /// added above it.
  testWidgets('the groups around it are untouched', (tester) async {
    await pump(tester, categories);

    for (final label in ['THE SHOP', 'TAKE PART', 'THE FOUNDATION', 'MEDIA']) {
      expect(find.text(label), findsOneWidget, reason: '$label went missing');
    }
  });

  /// The two tiles at the top are one size.
  ///
  /// "80G receipt by email" fits on one line and "List your work, no
  /// commission" does not, so the tiles were different heights and the shorter
  /// one sat centred against the taller with a gap above and below — two cards
  /// that plainly did not match.
  ///
  /// Found by their captions, which are unique to the tiles: "Become a Vendor"
  /// appears twice on this screen and "Donate" is also the tab.
  ///
  /// Measured across widths and both font sizes because the gap does not show
  /// at every size: at 390pt both captions happen to wrap to two lines and the
  /// tiles match by luck. At 360pt they did not — "Become a Vendor" takes two
  /// lines where "Donate" takes one, and the tiles came out 116 and 136. A
  /// test pinned to one width would have passed against the broken layout.
  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('the donate and vendor tiles match at ${width}pt x $scale', (tester) async {
        await pump(tester, categories, width: width, scale: scale);

        Size tileUnder(String caption) => tester.getSize(
              find.ancestor(of: find.text(caption), matching: find.byType(InkWell)).first,
            );

        final donate = tileUnder('80G receipt by email');
        final vendor = tileUnder('List your work, no commission');

        expect(donate.height, vendor.height, reason: 'the tiles are different heights');
        expect(donate.width, vendor.width, reason: 'the tiles are different widths');
      });
    }
  }

  /// Selling is called "Become a Vendor" here.
  ///
  /// It reaches this screen twice — the tile at the top and a row in The shop —
  /// and the two must never disagree, because a reader sees both at once and
  /// would read them as two different things.
  testWidgets('selling is named the same in both places', (tester) async {
    await pump(tester, categories);

    expect(find.text('Become a Vendor'), findsNWidgets(2));
    expect(find.text('Sell with us'), findsNothing);
  });
}
