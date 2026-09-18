import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takecare_connect/core/theme/app_colors.dart';
import 'package:takecare_connect/core/theme/app_text_styles.dart';
import 'package:takecare_connect/core/theme/app_theme.dart';
import 'package:takecare_connect/features/home/home_screen.dart';

/// The chrome that frames every screen, at the sizes real phones actually are.
///
/// The app bar overflowed by 133px on an RMX2002 — a 720×1600 screen, so 360pt
/// wide — and no screenshot caught it because they all ran at 390pt. An
/// overflow is not an exception the app catches: Flutter paints the
/// yellow-and-black hazard stripes and carries on, so nothing fails, nothing
/// logs, and it ships.
///
/// `tester.takeException()` is what turns it into a test failure.
///
/// This used to keep a hand-copied duplicate of the app bar and said so — a
/// test that measures a copy is a test asserting the wrong widget fits. It now
/// pumps `homeAppBar`, the real one, which is why that was extracted.
void main() {
  /// Every width worth caring about, from the narrowest Android still in use to
  /// a large phone, each at both normal and the largest font the app allows.
  const widths = <double>[320, 360, 390, 412, 430];
  const scales = <double>[1.0, 1.3];

  Future<void> pump(
    WidgetTester tester, {
    required Size size,
    required double scale,
    required Widget Function(BuildContext context) child,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, inner) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: inner!,
        ),
        home: Builder(builder: (context) => child(context)),
      ),
    );
    await tester.pump();
  }

  group('the home app bar', () {
    for (final width in widths) {
      for (final scale in scales) {
        testWidgets('fits at ${width.toInt()}pt at ${scale}x text', (tester) async {
          await pump(
            tester,
            size: Size(width, 800),
            scale: scale,
            child: (context) => Scaffold(
              body: CustomScrollView(
                slivers: [homeAppBar(context), const SliverToBoxAdapter(child: SizedBox(height: 1200))],
              ),
            ),
          );

          expect(
            tester.takeException(),
            isNull,
            reason: 'the app bar overflowed at ${width}pt, ${scale}x',
          );
        });
      }
    }
  });

  /// The tab bar, which gained a label when Craftsmen became Shop.
  ///
  /// Five labels in a fixed 62px-high row is the tightest piece of chrome in
  /// the app: the column inside each tab was already four pixels taller than
  /// the bar at the largest font on the narrowest phone, which is why it uses
  /// `mainAxisSize: min` and a `Flexible` label. This holds it to that.
  group('the tab bar', () {
    const labels = ['Home', 'Stories', 'Shop', 'Give', 'More'];

    for (final width in widths) {
      for (final scale in scales) {
        testWidgets('five tabs fit at ${width.toInt()}pt at ${scale}x text', (tester) async {
          await pump(
            tester,
            size: Size(width, 800),
            scale: scale,
            child: (context) => Scaffold(
              body: const SizedBox.expand(),
              bottomNavigationBar: SizedBox(
                height: 62,
                child: Row(
                  children: [
                    for (final label in labels)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.circle, size: 22),
                            const SizedBox(height: 3),
                            Flexible(
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.meta.copyWith(
                                  fontSize: 11,
                                  height: 1.1,
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );

          expect(
            tester.takeException(),
            isNull,
            reason: 'the tab bar overflowed at ${width}pt, ${scale}x',
          );
        });
      }
    }
  });
}
