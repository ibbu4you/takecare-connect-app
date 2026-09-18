import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takecare_connect/core/models/shop.dart';
import 'package:takecare_connect/core/theme/app_theme.dart';
import 'package:takecare_connect/core/widgets/ai_note.dart';
import 'package:takecare_connect/core/widgets/shop_cards.dart';

/// What the shop is not allowed to say.
///
/// Four words and phrases, and each one is a promise the foundation cannot
/// keep:
///
/// **"Buy"**, a cart, a basket, a quantity — no money passes through this app.
/// A reader contacts the maker and the two of them settle it between
/// themselves, so a button suggesting otherwise would be the app taking on a
/// role in somebody else's sale.
///
/// **"Verified"** and **"certified"** would turn an editorial listing into a
/// guarantee of somebody's goods. The foundation's own membership certificate
/// is tested for not making that claim; the app must not make it either.
///
/// **"Secure payment"** would simply be false.
///
/// This test is deliberately about absence, which is the hardest kind of rule
/// to keep: nothing fails when somebody adds a Buy button, it just ships.
void main() {
  final banned = RegExp(
    r'\b(buy|cart|basket|checkout|verified|certified|secure payment)',
    caseSensitive: false,
  );

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: child),
      ),
    );
    await tester.pump();
  }

  /// Every piece of text the widget tree actually renders.
  List<String> textsIn(WidgetTester tester) {
    return tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data ?? '')
        .where((value) => value.isNotEmpty)
        .toList();
  }

  final product = ShopProduct.fromJson(const {
    'slug': 'blue-serving-bowl',
    'name': 'Blue serving bowl',
    'price_label': '₹450 / piece',
    'ai_assisted': true,
    'category': {'slug': 'pottery', 'name': 'Pottery'},
    'maker': {'slug': 'selvi-pottery', 'name': 'Selvi Pottery', 'city': 'Khurja'},
  });

  final brand = Brand.fromJson(const {
    'slug': 'selvi-pottery',
    'name': 'Selvi Pottery',
    'product_count': 4,
    'since_year': 2021,
    'craft': {'slug': 'pottery', 'name': 'Pottery'},
    'city': {'slug': 'khurja', 'name': 'Khurja'},
  });

  testWidgets('a product card sells nothing', (tester) async {
    await pump(tester, SizedBox(height: 320, child: ProductCard(product: product)));

    for (final text in textsIn(tester)) {
      expect(banned.hasMatch(text), isFalse, reason: 'a product card said "$text"');
    }
  });

  testWidgets('a brand card claims nothing', (tester) async {
    await pump(tester, SizedBox(height: 320, child: BrandCard(brand: brand)));

    for (final text in textsIn(tester)) {
      expect(banned.hasMatch(text), isFalse, reason: 'a brand card said "$text"');
    }
  });

  testWidgets('a product card prints the price the server worded', (tester) async {
    await pump(tester, SizedBox(height: 320, child: ProductCard(product: product)));

    expect(find.text('₹450 / piece'), findsOneWidget);
  });

  testWidgets('a price-less product asks the maker, in those words', (tester) async {
    final unpriced = ShopProduct.fromJson(const {
      'slug': 'made-to-order',
      'name': 'Made to order',
    });

    await pump(tester, SizedBox(height: 320, child: ProductCard(product: unpriced)));

    expect(find.text('Ask the maker'), findsOneWidget);
  });

  testWidgets('a machine-tidied photograph says so on the card', (tester) async {
    await pump(tester, SizedBox(height: 320, child: ProductCard(product: product)));

    expect(find.text('AI enhanced'), findsOneWidget);
  });

  testWidgets('a card with an untouched photograph says nothing about AI', (tester) async {
    final plain = ShopProduct.fromJson(const {
      'slug': 'plain',
      'name': 'Plain',
      'price_label': '₹100',
    });

    await pump(tester, SizedBox(height: 320, child: ProductCard(product: plain)));

    expect(find.text('AI enhanced'), findsNothing);
  });

  testWidgets('the full note names what was changed and what was not', (tester) async {
    await pump(tester, const AiNote.sentence());

    expect(
      find.text('Photograph enhanced with AI. The item itself is unchanged.'),
      findsOneWidget,
    );
  });
}
