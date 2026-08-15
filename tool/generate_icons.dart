import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takecare_connect/core/theme/app_colors.dart';
import 'package:takecare_connect/core/widgets/tcif_logo.dart';

/// Renders the launcher icons from the same painter the app draws with.
///
/// Run it when the mark changes:
///
/// ```
/// flutter test tool/generate_icons.dart
/// flutter pub run flutter_launcher_icons
/// flutter pub run flutter_native_splash:create
/// ```
///
/// It lives here rather than in a design file because **there is no logo image
/// anywhere in this project** — on the website the mark is inline SVG in
/// `Components/Logo.tsx`, and in this app it is [TcifLogo]'s `CustomPainter`.
/// Exporting the PNGs from that painter is the only way to guarantee the icon
/// on the home screen is the same mark as the one inside the app; an icon
/// traced by hand would drift the first time either changed.
///
/// It is a test file only because `flutter test` is the one runner that gives a
/// plain Dart script a working `dart:ui` — rasterising a `Picture` needs a
/// Skia context, which `dart run` has no way to start.
void main() {
  testWidgets('writes the launcher icons', (tester) async {
    final directory = Directory('assets/icon');
    if (!directory.existsSync()) directory.createSync(recursive: true);

    // runAsync, not a bare await. `testWidgets` runs inside a fake async zone
    // where timers only advance when the test pumps — and `Picture.toImage`
    // hands its work to the raster thread and waits for a real callback that
    // will never arrive. Without this the first icon is written and the second
    // hangs until the ten-minute timeout.
    await tester.runAsync(() async {
      // The full-bleed icon: white plate, mark filling 78% of it. Every
      // platform rounds the corners, so a little air is needed — but only a
      // little, because this is rendered at 48px on a home screen.
      await _write(
        path: 'assets/icon/app_icon.png',
        background: AppColors.background,
        fill: 0.78,
      );

      // The adaptive foreground. Android masks this to a circle, a squircle or
      // a teardrop depending on the launcher, and it also *animates* it —
      // parallax shifts the layer within the mask. Only the middle 66% is
      // guaranteed to survive, and the laurel tips are the outermost thing in
      // this mark, so it is drawn well inside that.
      await _write(
        path: 'assets/icon/app_icon_foreground.png',
        background: null,
        fill: 0.56,
      );
    });

    // Neither store accepts a PNG with an alpha channel for the store listing,
    // but flutter_launcher_icons handles that with `remove_alpha_ios`.
    expect(File('assets/icon/app_icon.png').existsSync(), isTrue);
    expect(File('assets/icon/app_icon_foreground.png').existsSync(), isTrue);
  });
}

const _size = 1024.0;

/// Where the ink actually is inside the 48×48 viewBox.
///
/// **Not** `0 0 48 48`. The laurel's outermost point is around x=6.7 and the
/// arcs stop well short of the bottom edge, so the drawn mark occupies about
/// 72% of the box width and sits fractionally low. Scaling to the box rather
/// than to this rectangle is what made the first pass come out small and
/// off-centre — a launcher icon has no room to waste on empty viewBox.
///
/// The bounds include half a stroke width on every side, because the laurel is
/// stroked with round caps and the geometry alone would clip them.
const _content = Rect.fromLTRB(6.7, 8.8, 41.3, 40.6);

Future<void> _write({
  required String path,
  required Color? background,
  required double fill,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, _size, _size));

  if (background != null) {
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, _size, _size),
      Paint()..color = background,
    );
  }

  // Scale on the longer edge so the mark keeps its proportions, then centre on
  // the content's own centre rather than the viewBox's.
  final scale = _size * fill / (_content.width > _content.height ? _content.width : _content.height);

  canvas
    ..translate(_size / 2, _size / 2)
    ..scale(scale)
    ..translate(-_content.center.dx, -_content.center.dy);

  // The painter is private to tcif_logo.dart, so the mark goes through the
  // widget's paint hook rather than reaching for the painter directly. Painted
  // at its native 48 units, since the canvas is already scaled.
  const TcifLogo(size: 48, color: AppColors.primary).paintTo(canvas, 48);

  final image = await recorder.endRecording().toImage(_size.toInt(), _size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());

  // ignore: avoid_print
  print('wrote $path');
}
