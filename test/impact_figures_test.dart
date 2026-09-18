import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takecare_connect/core/models/home.dart';
import 'package:takecare_connect/core/theme/app_theme.dart';
import 'package:takecare_connect/features/home/sections/impact_band.dart';

/// The stat panels in the impact band, which have to be the same size.
///
/// They were laid out with a Wrap, which sizes every child to its own content:
/// "Subjects covered" fits on one line and "Businesses interviewed" does not,
/// so the two panels beside each other came out visibly different heights and
/// the grid read as broken. The fifth figure then sat alone in a half-width
/// tile with a hole beside it.
///
/// The live set is the five below, and it is deliberately odd-numbered —
/// that is the case that exposed both faults.
void main() {
  const stats = <ImpactStat>[
    ImpactStat(value: '100+', label: 'Stories published'),
    ImpactStat(value: '10', label: 'Businesses interviewed'),
    ImpactStat(value: '6', label: 'Subjects covered'),
    ImpactStat(value: '4', label: 'Live campaigns'),
    ImpactStat(value: 'One', label: 'Brighter India'),
  ];

  /// Narrowest Android still in use, a common size, and a large phone — each at
  /// the normal font and at the largest the app allows.
  const widths = <double>[320, 360, 390, 430];
  const scales = <double>[1.0, 1.3];

  Future<void> pump(WidgetTester tester, {required double width, required double scale}) async {
    // Tall enough that nothing is clipped by the surface itself, which would
    // hide exactly the overflow this is looking for.
    await tester.binding.setSurfaceSize(Size(width, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, inner) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: inner!,
        ),
        home: const SingleChildScrollView(
          child: ImpactBand(stats: stats, testimonials: [], image: null),
        ),
      ),
    );
  }

  for (final width in widths) {
    for (final scale in scales) {
      testWidgets('every panel is the same height at ${width}pt × $scale', (tester) async {
        await pump(tester, width: width, scale: scale);

        expect(tester.takeException(), isNull, reason: 'the band overflowed');

        // The label sits in a box reserving two lines whether it needs them or
        // not, so every one of these is identical. That is what makes the
        // panels identical: one line of figure and two of label, everywhere.
        //
        // Compared with a tolerance, not for equality: the reserved height is
        // a font size times a leading times two, and that arithmetic lands on
        // 31.200000000000003 for one panel and 31.19999999999999 for the next.
        // A tenth of a pixel is not the raggedness this is guarding against.
        final heights = stats.map((stat) => tester.getRect(find.text(stat.label)).height).toList();

        for (final height in heights) {
          expect(
            height,
            closeTo(heights.first, 0.1),
            reason: 'label boxes differ, so the panels are different heights: $heights',
          );
        }
      });
    }
  }

  testWidgets('two to a row, and the odd one spans the width', (tester) async {
    await pump(tester, width: 390, scale: 1.0);

    Rect rectFor(int index) => tester.getRect(find.text(stats[index].label));

    // The first two share a row: same top edge, side by side.
    expect(rectFor(0).top, rectFor(1).top);
    expect(rectFor(0).right, lessThan(rectFor(1).left));

    // The third starts a new row below them.
    expect(rectFor(2).top, greaterThan(rectFor(0).bottom));

    // The fifth has no partner, so it takes the whole width rather than
    // leaving a half-width gap beside itself.
    expect(rectFor(4).width, greaterThan(rectFor(0).width * 1.8));
  });

  /// The band has to survive an empty or short set — `stats` comes from the
  /// server and a fresh install has counted nothing yet.
  testWidgets('a short set still lays out', (tester) async {
    for (final count in [0, 1, 2, 3]) {
      await tester.binding.setSurfaceSize(const Size(390, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: SingleChildScrollView(
            child: ImpactBand(
              stats: stats.take(count).toList(),
              testimonials: const [],
              image: null,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull, reason: '$count figures overflowed');

      // The invitation is never gated on the figures: it is the only route to
      // volunteering on the home page.
      expect(find.text('Join a growing community'), findsOneWidget);
    }
  });
}
