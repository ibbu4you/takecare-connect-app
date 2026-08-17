import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takecare_connect/core/theme/app_text_styles.dart';
import 'package:takecare_connect/core/theme/app_theme.dart';
import 'package:takecare_connect/core/widgets/tcif_logo.dart';

/// The home app bar, at the sizes real phones actually are.
///
/// It overflowed by 133px on an RMX2002 — a 720×1600 screen, so 360pt wide —
/// and no screenshot caught it because they all ran at 390pt. An overflow is
/// not an exception the app catches: Flutter paints the yellow-and-black
/// hazard stripes and carries on, so nothing fails, nothing logs, and it ships.
///
/// `tester.takeException()` is what turns it into a test failure.
void main() {
  Future<void> pumpBar(WidgetTester tester, {required Size size, double scale = 1.0}) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          // Kept in step with HomeScreen by hand, which is the weakness of this
          // test — but the alternative is pumping the whole screen with a fake
          // repository behind it, and what is being measured is one strip of
          // chrome, not the app.
          appBar: AppBar(
            leadingWidth: 58,
            leading: const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Center(child: TcifLogo(size: 30)),
            ),
            titleSpacing: 10,
            title: Text(
              'Takecare Connect',
              style: AppText.title.copyWith(fontSize: 17),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded)),
            ],
          ),
          body: const SizedBox.expand(),
        ),
      ),
    );
  }

  /// Every width worth caring about, from the narrowest Android still in use
  /// to a large phone, each at both normal and the largest font the app allows.
  const widths = <double>[320, 360, 390, 412, 430];

  for (final width in widths) {
    for (final scale in const [1.0, 1.3]) {
      testWidgets('fits at ${width.toInt()}pt at ${scale}x text', (tester) async {
        await pumpBar(tester, size: Size(width, 800), scale: scale);

        expect(
          tester.takeException(),
          isNull,
          reason: 'the app bar overflowed at ${width}pt, ${scale}x',
        );
      });
    }
  }
}
