import 'package:flutter/material.dart';

/// The website's palette, verbatim.
///
/// Every value here is one of the HSL custom properties in the site's
/// `resources/css/app.css`, converted to hex. They are duplicated rather than
/// fetched because a colour that changes on the web should be a deliberate
/// change here too — an app that repainted itself when somebody edited a
/// stylesheet would be worse, not better.
///
/// One rule governs the whole palette and is worth stating plainly:
/// **[accent] is reserved.** Red belongs to donate calls to action, progress
/// bars and eyebrow labels. Everything structural — app bars, buttons, links,
/// active states — is [primary] navy. The site's own Tailwind config says so,
/// and an app that spends the red elsewhere makes the donate button ordinary.
class AppColors {
  AppColors._();

  static const background = Color(0xFFFFFFFF);
  static const foreground = Color(0xFF1A1F36);

  /// The tint behind alternating sections and inset panels.
  static const surface = Color(0xFFF5F7FB);

  static const primary = Color(0xFF283A8E);
  static const primaryDark = Color(0xFF1E2C6B);
  static const primaryForeground = Color(0xFFFFFFFF);

  /// Donate CTAs, progress bars and eyebrows. Nothing else.
  static const accent = Color(0xFFE63946);
  static const accentDark = Color(0xFFC22B38);
  static const accentForeground = Color(0xFFFFFFFF);

  static const success = Color(0xFF1B7350);
  static const successForeground = Color(0xFFFFFFFF);

  static const mutedForeground = Color(0xFF5A6178);

  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE4E8F0);

  /// The dark band at the foot of the site, reused for the More tab's header.
  static const footer = Color(0xFF121A2B);
  static const footerDeep = Color(0xFF0B1020);
  static const footerForeground = Color(0xFFFFFFFF);
  static const footerMuted = Color(0xFFB3BCD4);

  static const destructive = accent;
}

/// The radius vocabulary, so a screen never invents its own.
///
/// Taken from the site: `--radius` is 12px, cards sit one step up at 16, pills
/// are fully round. Shadows are deliberately almost absent in this design —
/// borders carry the elevation — so radius is what gives the UI its shape.
class AppRadii {
  AppRadii._();

  static const small = 8.0;

  /// Fields, buttons, snackbars.
  static const field = 12.0;

  static const tile = 14.0;

  /// Cards.
  static const card = 16.0;

  static const hero = 20.0;

  /// Chips and pills.
  static const pill = 999.0;
}
