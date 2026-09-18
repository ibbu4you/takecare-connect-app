library;

import 'package:flutter/foundation.dart';

/// What the shop is currently showing.
///
/// **Why this is a class and not a record.** Every other paged list in this app
/// keys its family on a record, because records have structural equality in
/// Dart — `(category: 'weaving')` is the same provider instance however many
/// widgets ask for it. That stops working the moment a field is a `List`:
/// `['a'] != ['a']`, so a record holding one is never equal to an identical
/// record, and the family would mint a fresh notifier on every rebuild. The
/// shop would refetch on each keystroke of the search field and the reader's
/// place in the list would be thrown away with it.
///
/// So the equality is written by hand, over sorted copies of the lists — ticking
/// pottery then bamboo is the same query as ticking bamboo then pottery, and it
/// should not be two.
@immutable
class ProductsQuery {
  ProductsQuery({
    List<String> categories = const [],
    List<String> makers = const [],
    this.city,
    this.q,
    this.priceMin,
    this.priceMax,
  })  : categories = List.unmodifiable(categories.toSet().toList()..sort()),
        makers = List.unmodifiable(makers.toSet().toList()..sort());

  /// Sorted and deduplicated at construction, so two orderings of the same
  /// ticks are one query.
  final List<String> categories;
  final List<String> makers;

  final String? city;
  final String? q;
  final double? priceMin;
  final double? priceMax;

  static final empty = ProductsQuery();

  /// How many filters the reader has applied, for the badge on the filter
  /// button. The search term is not one of them — it has its own field on
  /// screen, so counting it would say "1 filter" about something visible.
  int get appliedCount =>
      categories.length +
      makers.length +
      (city == null ? 0 : 1) +
      (priceMin == null ? 0 : 1) +
      (priceMax == null ? 0 : 1);

  bool get hasFilters => appliedCount > 0;

  ProductsQuery copyWith({
    List<String>? categories,
    List<String>? makers,
    String? city,
    String? q,
    double? priceMin,
    double? priceMax,
    bool clearCity = false,
    bool clearQuery = false,
    bool clearPrices = false,
  }) {
    return ProductsQuery(
      categories: categories ?? this.categories,
      makers: makers ?? this.makers,
      city: clearCity ? null : (city ?? this.city),
      q: clearQuery ? null : (q ?? this.q),
      priceMin: clearPrices ? null : (priceMin ?? this.priceMin),
      priceMax: clearPrices ? null : (priceMax ?? this.priceMax),
    );
  }

  /// Everything cleared except the search term, which is the one thing the
  /// reader can see they typed.
  ProductsQuery cleared() => ProductsQuery(q: q);

  @override
  bool operator ==(Object other) {
    if (other is! ProductsQuery) return false;

    return listEquals(categories, other.categories) &&
        listEquals(makers, other.makers) &&
        city == other.city &&
        q == other.q &&
        priceMin == other.priceMin &&
        priceMax == other.priceMax;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(categories),
        Object.hashAll(makers),
        city,
        q,
        priceMin,
        priceMax,
      );

  @override
  String toString() => 'ProductsQuery(categories: $categories, makers: $makers, '
      'city: $city, q: $q, priceMin: $priceMin, priceMax: $priceMax)';
}
