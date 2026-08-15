import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// DM Sans, at the sizes the website uses.
///
/// The site self-hosts three weights — 400, 500 and 700 — and declares DM Sans
/// as the only family it loads. `google_fonts` is used here rather than
/// bundling the same woff2 files, because it is what the sibling app already
/// does and it keeps the APK smaller.
///
/// Sizes are the website's, stepped down where a phone needs it: a 48px hero
/// heading is right on a 1400px page and absurd on a 390px screen.
class AppText {
  AppText._();

  static TextStyle _dm({
    required FontWeight weight,
    required double size,
    Color color = AppColors.foreground,
    double height = 1.4,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.dmSans(
      fontWeight: weight,
      fontSize: size,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Detail-page headings. The site runs 30→36px; 28 reads better on a phone.
  static TextStyle h1 = _dm(weight: FontWeight.w700, size: 28, height: 1.15);

  /// Section headings.
  static TextStyle h2 = _dm(weight: FontWeight.w700, size: 22, height: 1.2);

  /// Card titles.
  static TextStyle h3 = _dm(weight: FontWeight.w700, size: 18, height: 1.25);

  static TextStyle title = _dm(weight: FontWeight.w700, size: 16, height: 1.3);

  /// Body copy and prose.
  static TextStyle body = _dm(weight: FontWeight.w400, size: 16, height: 1.6);

  static TextStyle bodyStrong = _dm(weight: FontWeight.w600, size: 16, height: 1.5);

  /// The standfirst above an article.
  static TextStyle lead = _dm(weight: FontWeight.w400, size: 17, height: 1.6);

  /// Card excerpts.
  static TextStyle excerpt = _dm(
    weight: FontWeight.w400,
    size: 14,
    height: 1.5,
    color: AppColors.mutedForeground,
  );

  /// Bylines, dates, reading time.
  static TextStyle meta = _dm(
    weight: FontWeight.w400,
    size: 12,
    color: AppColors.mutedForeground,
  );

  static TextStyle metaStrong = _dm(weight: FontWeight.w600, size: 12);

  /// The small uppercase label above a section heading. Always accent red —
  /// this is one of the three places that colour is allowed.
  static TextStyle eyebrow = _dm(
    weight: FontWeight.w600,
    size: 12,
    color: AppColors.accent,
    letterSpacing: 1.2,
  );

  static TextStyle button = _dm(weight: FontWeight.w600, size: 15);

  /// A campaign's raised figure, and the price on an offer card.
  static TextStyle figure = _dm(weight: FontWeight.w700, size: 26, height: 1.1);
}
