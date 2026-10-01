import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takecare_connect/core/models/shop.dart';
import 'package:takecare_connect/core/state/providers.dart';
import 'package:takecare_connect/core/theme/app_theme.dart';
import 'package:takecare_connect/features/shop/brand_screen.dart';
import 'package:takecare_connect/features/shop/product_screen.dart';

/// No button reaches a maker without the form first, as on the website.
///
/// Call and WhatsApp used to dial straight away on a product and a brand page.
/// The website puts every way of reaching a maker behind its short form, so
/// the foundation has a record that somebody did, and hands the number back
/// once the reader has said who is calling. These hold the app to that.
void main() {
  const contact = {
    'phone': '9876512345',
    'whatsapp': 'https://wa.me/919876512345',
    'email': 'selvi@example.test',
  };

  Future<void> pump(WidgetTester tester, Widget screen, List<Override> overrides) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(theme: AppTheme.light(), home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('a product', () {
    final product = ShopProductDetail.fromJson(const {
      'slug': 'cane-bowl',
      'name': 'Cane bowl',
      'price_label': 'Ask the maker',
      'can_call': true,
      'can_enquire': true,
      'maker': {'slug': 'selvi', 'name': 'Selvi Pottery', 'contact': contact},
    });

    Future<void> open(WidgetTester tester) => pump(
          tester,
          const ProductScreen(slug: 'cane-bowl'),
          [productProvider('cane-bowl').overrideWith((ref) => product)],
        );

    testWidgets('has no WhatsApp button that skips the form', (tester) async {
      await open(tester);

      expect(find.bySemanticsLabel('WhatsApp the maker'), findsNothing);
      expect(find.byIcon(Icons.chat_outlined), findsNothing);
    });

    testWidgets('asks who is calling before the number', (tester) async {
      await open(tester);

      await tester.tap(find.byIcon(Icons.call_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Get their number'), findsOneWidget);
      expect(find.text('Show the number'), findsOneWidget);
    });

    testWidgets('"Ask about this" opens on the message, not the number', (tester) async {
      await open(tester);

      await tester.tap(find.text('Ask about this'));
      await tester.pumpAndSettle();

      expect(find.text('Send an enquiry'), findsOneWidget);
    });
  });

  group('a brand', () {
    final brand = Brand.fromJson(const {
      'slug': 'selvi',
      'name': 'Selvi Pottery',
      'owner_name': 'Selvi',
      'contact': contact,
      'can_call': true,
      'can_enquire': true,
    });

    Future<void> open(WidgetTester tester) => pump(
          tester,
          const BrandScreen(slug: 'selvi'),
          [brandProvider('selvi').overrideWith((ref) => brand)],
        );

    testWidgets("has the website's two buttons, and no dial or WhatsApp", (tester) async {
      await open(tester);

      expect(find.text('Message Selvi Pottery'), findsOneWidget);
      expect(find.text('View their number'), findsOneWidget);
      expect(find.text('WhatsApp'), findsNothing);
      expect(find.text('Call'), findsNothing);
    });

    testWidgets('"View their number" asks who is calling first', (tester) async {
      await open(tester);

      await tester.ensureVisible(find.text('View their number'));
      await tester.tap(find.text('View their number'));
      await tester.pumpAndSettle();

      expect(find.text('Get their number'), findsOneWidget);
    });

    testWidgets('"Message" opens on the message', (tester) async {
      await open(tester);

      await tester.ensureVisible(find.text('Message Selvi Pottery'));
      await tester.tap(find.text('Message Selvi Pottery'));
      await tester.pumpAndSettle();

      expect(find.text('Send an enquiry'), findsOneWidget);
    });
  });
}
