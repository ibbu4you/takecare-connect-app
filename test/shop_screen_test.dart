import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takecare_connect/core/api/cursor_page.dart';
import 'package:takecare_connect/core/models/shop.dart';
import 'package:takecare_connect/core/state/products_query.dart';
import 'package:takecare_connect/core/state/providers.dart';
import 'package:takecare_connect/features/shop/shop_screen.dart';

/// The Shop tab, drawn as the website's /shop is on a phone.
///
/// It used to open on craftsmen, because the craftsmen pages lived in this
/// tab's history. These hold the shop to the website's page instead: its
/// heading, its Filters panel, its count, sort and chips, and its products.
void main() {
  final asked = <ProductsQuery>[];

  final products = [
    ShopProduct.fromJson(const {
      'slug': 'noni-soap',
      'name': 'Eden Noni Turmeric Soap with a name long enough to wrap twice',
      'tagline': 'Cold-pressed in the Nilgiris',
      'price_label': '₹100',
      'category': {'slug': 'soaps', 'name': 'Handmade soaps and body care'},
      'maker': {'slug': 'eden', 'name': 'Eden Food Park', 'city': 'Ooty'},
    }),
    ShopProduct.fromJson(const {
      'slug': 'bowl',
      'name': 'Blue serving bowl',
      'price_label': 'Ask the maker',
    }),
  ];

  Future<void> pump(WidgetTester tester,
      {Size size = const Size(390, 2400), double scale = 1}) async {
    asked.clear();
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productsProvider.overrideWith(() => _Shelf(asked, products)),
          shopFiltersProvider.overrideWith(
            (ref) async => ShopFilters.fromJson(const {
              'categories': [
                {'slug': 'soaps', 'name': 'Handmade soaps and body care', 'count': 4},
                {'slug': 'pottery', 'name': 'Pottery', 'count': 2},
              ],
              'makers': [
                {'slug': 'eden', 'name': 'Eden Food Park', 'count': 4},
              ],
              'cities': [
                {'slug': 'ooty', 'name': 'Ooty'},
              ],
            }),
          ),
        ],
        child: MaterialApp(
          builder: (context, inner) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: inner!,
          ),
          home: const ShopScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets("it opens on the website's shop, not on craftsmen", (tester) async {
    await pump(tester);

    expect(find.text('Products by our makers'), findsOneWidget);
    expect(find.textContaining('we take no part in the sale'), findsOneWidget);
    expect(find.text('Search'), findsWidgets);
    expect(find.text('Clear all'), findsOneWidget);
    expect(find.text('Latest'), findsOneWidget);
    expect(find.text('View details'), findsNWidgets(2));
    expect(find.text('₹100'), findsOneWidget);
    expect(find.text('Read the interviews'), findsNothing);
  });

  testWidgets('it says how many there are, from the server', (tester) async {
    await pump(tester);

    expect(find.textContaining('Showing 7 products'), findsOneWidget);
  });

  testWidgets('the ticks open from Filters, and nothing changes until Apply', (tester) async {
    await pump(tester);

    expect(find.text('Categories'), findsNothing);

    await tester.tap(find.text('Filters').last);
    await tester.pump();

    expect(find.text('Hide filters'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Makers'), findsOneWidget);
    expect(find.text('Price Range'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);

    await tester.tap(find.text('Pottery'));
    await tester.pump();
    expect(asked.last.categories, isEmpty, reason: 'a tick applied itself');

    await tester.ensureVisible(find.text('Apply Filters'));
    await tester.tap(find.text('Apply Filters'));
    await tester.pump();
    await tester.pump();

    expect(asked.last.categories, ['pottery']);
    expect(find.text('Categories'), findsNothing, reason: 'the panel stayed open');

    // The chip for it, which removes it again.
    final chip = find.text('Pottery');
    expect(chip, findsOneWidget);
    await tester.tap(chip);
    await tester.pump();
    await tester.pump();

    expect(asked.last.categories, isEmpty);
  });

  testWidgets("the sort sends the website's order", (tester) async {
    await pump(tester);

    await tester.tap(find.text('Latest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Price: low to high').last);
    await tester.pumpAndSettle();

    expect(asked.last.sort, 'price_asc');
  });

  testWidgets('search sends what was typed, and shows it as a chip', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'soap');
    await tester.tap(find.widgetWithText(FilledButton, 'Search'));
    await tester.pump();
    await tester.pump();

    expect(asked.last.q, 'soap');
    expect(find.text('Search: “soap”'), findsOneWidget);
  });

  testWidgets('the list view is the website\'s row', (tester) async {
    await pump(tester);

    await tester.tap(find.bySemanticsLabel('List view'));
    await tester.pump();

    expect(find.text('Cold-pressed in the Nilgiris'), findsOneWidget);
    expect(find.text('View details'), findsNWidgets(2));
  });

  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('nothing overflows at ${width.toInt()}pt and ${scale}x text', (tester) async {
        await pump(tester, size: Size(width, 3000), scale: scale);

        await tester.tap(find.text('Filters').last);
        await tester.pump();
        expect(tester.takeException(), isNull);

        await tester.tap(find.bySemanticsLabel('List view'));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  }
}

/// The shelf, without a server: records what it was asked for.
class _Shelf extends ProductsNotifier {
  _Shelf(this.asked, this.products);

  final List<ProductsQuery> asked;
  final List<ShopProduct> products;

  @override
  Future<CursorPage<ShopProduct>> fetch(ProductsQuery query, String? cursor) async {
    asked.add(query);

    return CursorPage(items: products, total: 7);
  }
}
