import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The TCIF mark: a heart inside a laurel wreath.
///
/// Transcribed path-for-path from the website's `Components/Logo.tsx`, which is
/// inline SVG on a 48×48 viewBox. There is no logo image file anywhere in the
/// project — the mark only exists as those path commands — so it is redrawn
/// here rather than shipped as an asset. Dart's `Path` mirrors SVG commands
/// closely enough that the translation is mechanical: `c` becomes
/// `relativeCubicTo`, `M` becomes `moveTo`, every coordinate scaled by
/// `size / 48`.
///
/// [color] paints the laurel and stands in for the SVG's `currentColor`, so the
/// mark goes navy on white and white on the footer's dark band exactly as it
/// does on the web. **The heart is always accent red**, whatever [color] says —
/// that is what `className="fill-accent"` encodes on the original, and it is
/// the one part of the mark that carries brand colour.
class TcifLogo extends StatelessWidget {
  const TcifLogo({super.key, this.size = 36, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Take Care International Foundation',
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _TcifLogoPainter(color: color ?? AppColors.primary),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  /// Paints the mark straight onto a canvas, outside the widget tree.
  ///
  /// Used by `tool/generate_icons.dart` to rasterise the launcher icons from
  /// this exact painter. It exists so the icon and the in-app mark cannot
  /// drift apart: there is no logo image file in this project to fall back on,
  /// so a hand-traced icon would be a second source of truth for the brand.
  void paintTo(Canvas canvas, double edge) {
    _TcifLogoPainter(color: color ?? AppColors.primary).paint(canvas, Size(edge, edge));
  }
}

class _TcifLogoPainter extends CustomPainter {
  const _TcifLogoPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 48;

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * s
      ..strokeCap = StrokeCap.round;

    final leaf = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round;

    // M13 10c-5 5-6.5 12-4 19 1.6 4.4 4.4 7.9 8 10.4
    final leftArc = Path()
      ..moveTo(13 * s, 10 * s)
      ..relativeCubicTo(-5 * s, 5 * s, -6.5 * s, 12 * s, -4 * s, 19 * s)
      ..relativeCubicTo(1.6 * s, 4.4 * s, 4.4 * s, 7.9 * s, 8 * s, 10.4 * s);
    canvas.drawPath(leftArc, arc);

    // M35 10c5 5 6.5 12 4 19-1.6 4.4-4.4 7.9-8 10.4
    final rightArc = Path()
      ..moveTo(35 * s, 10 * s)
      ..relativeCubicTo(5 * s, 5 * s, 6.5 * s, 12 * s, 4 * s, 19 * s)
      ..relativeCubicTo(-1.6 * s, 4.4 * s, -4.4 * s, 7.9 * s, -8 * s, 10.4 * s);
    canvas.drawPath(rightArc, arc);

    // Three leaves a side, each its own subpath.
    final leftLeaves = Path()
      ..moveTo(11.5 * s, 16.5 * s)
      ..relativeCubicTo(2.6 * s, -0.4 * s, 4.6 * s, 0.6 * s, 5.6 * s, 2.9 * s)
      ..moveTo(10 * s, 23.5 * s)
      ..relativeCubicTo(2.6 * s, -0.1 * s, 4.4 * s, 1.1 * s, 5.2 * s, 3.5 * s)
      ..moveTo(11 * s, 30.5 * s)
      ..relativeCubicTo(2.4 * s, 0.4 * s, 4 * s, 1.8 * s, 4.4 * s, 4.2 * s);
    canvas.drawPath(leftLeaves, leaf);

    final rightLeaves = Path()
      ..moveTo(36.5 * s, 16.5 * s)
      ..relativeCubicTo(-2.6 * s, -0.4 * s, -4.6 * s, 0.6 * s, -5.6 * s, 2.9 * s)
      ..moveTo(38 * s, 23.5 * s)
      ..relativeCubicTo(-2.6 * s, -0.1 * s, -4.4 * s, 1.1 * s, -5.2 * s, 3.5 * s)
      ..moveTo(37 * s, 30.5 * s)
      ..relativeCubicTo(-2.4 * s, 0.4 * s, -4 * s, 1.8 * s, -4.4 * s, 4.2 * s);
    canvas.drawPath(rightLeaves, leaf);

    // M24 34.5s-8.4-5.2-8.4-11.1a4.9 4.9 0 0 1 8.4-3.4 4.9 4.9 0 0 1 8.4 3.4
    // c0 5.9-8.4 11.1-8.4 11.1Z
    //
    // The two `a` arcs are the lobes. SVG's elliptical-arc command has no Dart
    // equivalent, so they are drawn as arcs on their bounding circles: both
    // have r=4.9 and centres 4.2 either side of the midline, which is what the
    // original's control points work out to.
    final heart = Path()
      ..moveTo(24 * s, 34.5 * s)
      ..relativeCubicTo(0, 0, -8.4 * s, -5.2 * s, -8.4 * s, -11.1 * s)
      ..arcToPoint(
        Offset(24 * s, 20.1 * s),
        radius: Radius.circular(4.9 * s),
        clockwise: true,
      )
      ..arcToPoint(
        Offset(32.4 * s, 23.4 * s),
        radius: Radius.circular(4.9 * s),
        clockwise: true,
      )
      ..relativeCubicTo(0, 5.9 * s, -8.4 * s, 11.1 * s, -8.4 * s, 11.1 * s)
      ..close();

    canvas.drawPath(
      heart,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_TcifLogoPainter oldDelegate) => oldDelegate.color != color;
}
