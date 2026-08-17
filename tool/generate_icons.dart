import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:takecare_connect/core/theme/app_colors.dart';
import 'package:takecare_connect/core/widgets/tcif_logo.dart';

/// Cuts the launcher icons from the app's own logo asset.
///
/// Run it whenever the logo changes:
///
/// ```
/// flutter test tool/generate_icons.dart
/// dart run flutter_launcher_icons
/// dart run flutter_native_splash:create
/// ```
///
/// It exists so the icon on the home screen and the mark inside the app are cut
/// from **the same file** — `assets/brand/tcif_logo.png`, the foundation's
/// badge. Exporting the icon by hand from some other copy is how an app ends up
/// with two slightly different logos and nobody noticing which is current.
///
/// It is a test file only because `flutter test` is the one runner that gives a
/// plain Dart script a working `dart:ui`: rasterising a `Picture` needs a Skia
/// context, which `dart run` has no way to start.
void main() {
  testWidgets('cuts the launcher icons from the logo asset', (tester) async {
    final directory = Directory('assets/icon');
    if (!directory.existsSync()) directory.createSync(recursive: true);

    // runAsync, not a bare await. `testWidgets` runs inside a fake async zone
    // where timers only advance when the test pumps — and both `decodeImage`
    // and `Picture.toImage` hand their work to the raster thread and wait for a
    // real callback that would never arrive.
    await tester.runAsync(() async {
      final logo = await _decodeAsset(TcifLogo.asset);

      // The full-bleed icon: white plate, badge at 86%. A circular mark can sit
      // closer to the edge than a square one, because every platform's rounding
      // follows the same curve it does.
      await _write(
        logo,
        path: 'assets/icon/app_icon.png',
        background: AppColors.background,
        fill: 0.86,
      );

      // The adaptive foreground. Android masks this to a circle, a squircle or
      // a teardrop depending on the launcher, and it also *animates* it —
      // parallax shifts the layer inside the mask. Only the middle 66% is
      // guaranteed, and the rim lettering is the first thing a mask eats.
      await _write(
        logo,
        path: 'assets/icon/app_icon_foreground.png',
        background: null,
        fill: 0.62,
      );

      logo.dispose();
    });

    expect(File('assets/icon/app_icon.png').existsSync(), isTrue);
    expect(File('assets/icon/app_icon_foreground.png').existsSync(), isTrue);
  });
}

const _size = 1024.0;

Future<ui.Image> _decodeAsset(String key) async {
  final data = await rootBundle.load(key);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());

  return (await codec.getNextFrame()).image;
}

Future<void> _write(
  ui.Image logo, {
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

  final side = _size * fill;
  final offset = (_size - side) / 2;

  canvas.drawImageRect(
    logo,
    Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble()),
    Rect.fromLTWH(offset, offset, side, side),
    // The source is 379px square and the target is up to 880, so this is an
    // upscale — high filter quality is what keeps the rim lettering from
    // turning to stair-steps.
    Paint()..filterQuality = FilterQuality.high,
  );

  final image = await recorder.endRecording().toImage(_size.toInt(), _size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
  image.dispose();

  // ignore: avoid_print
  print('wrote $path');
}
