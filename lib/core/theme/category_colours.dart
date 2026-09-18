library;

import 'package:flutter/material.dart';

/// The colour a post category is drawn in when it has no cover photograph.
///
/// Ported from the website's CategoryTiles so a subject looks the same in both
/// places — a reader who knows "Tales of Brands" as the violet tile should not
/// find it amber on their phone. The palette, the hash and the
/// no-two-neighbours-alike rule are all the website's, and the Tailwind class
/// names it uses are resolved to their actual values here.
class CategoryColours {
  CategoryColours._();

  /// Tailwind's 500 shades, in the website's order — which is deliberate: the
  /// next entry along is a different hue rather than the next shade of the
  /// same, so stepping off a duplicate lands somewhere visibly different.
  static const _palette = <Color>[
    Color(0xFFF43F5E), // rose-500
    Color(0xFF10B981), // emerald-500
    Color(0xFF8B5CF6), // violet-500
    Color(0xFFF59E0B), // amber-500
    Color(0xFF0EA5E9), // sky-500
    Color(0xFFD946EF), // fuchsia-500
    Color(0xFF14B8A6), // teal-500
    Color(0xFFF97316), // orange-500
    Color(0xFF6366F1), // indigo-500
    Color(0xFF65A30D), // lime-600
  ];

  /// Derived from the slug rather than from a position in the list, so a
  /// category keeps its colour when the office adds, removes or reorders one. A
  /// tile that changed colour every time a story was published would read as
  /// decoration rather than as something you recognise.
  static int _hashOf(String slug) {
    var hash = 0;

    for (final unit in slug.codeUnits) {
      hash = (hash * 31 + unit) % 100000;
    }

    return hash;
  }

  /// The colours for a whole row, with no two neighbours alike.
  ///
  /// The hash alone put an orange beside an amber, which undoes the one thing
  /// giving every category a colour is for. So a tile that lands on the colour
  /// before it steps to the next one along.
  ///
  /// The cost is the website's too, and it is honest: a category's colour
  /// depends on its neighbour, so it can change when the row is reordered.
  /// Reordering happens when the story counts change, which is rare; a
  /// duplicate would be visible every single time.
  static List<Color> run(List<String> slugs) {
    final chosen = <Color>[];

    for (var index = 0; index < slugs.length; index++) {
      var at = _hashOf(slugs[index]) % _palette.length;

      if (index > 0 && _palette[at] == chosen[index - 1]) {
        at = (at + 1) % _palette.length;
      }

      chosen.add(_palette[at]);
    }

    return chosen;
  }
}
