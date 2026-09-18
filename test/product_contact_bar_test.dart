import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takecare_connect/core/models/shop.dart';
import 'package:takecare_connect/core/state/providers.dart';
import 'package:takecare_connect/core/theme/app_theme.dart';
import 'package:takecare_connect/features/shop/product_screen.dart';

/// The bar along the foot of a product.
///
/// The number is an icon on its own — "Their number" beside a handset said
/// nothing the handset does not, and it was taking a third of the bar from the
/// button most readers actually want.
///
/// The two flags are never collapsed into one. Whether an enquiry reaches
/// anybody and whether there is a number to reveal are different questions with
/// different answers, both decided by the server, and the bar has a different
/// shape for each combination.
void main() {
  const product = ShopProductDetail(
    slug: 'cane-bowl',
    name: 'Cane bowl',
    priceLabel: 'Ask the maker',
  );

  Future<void> pump(
    WidgetTester tester,
    ShopProductDetail detail, {
    double width = 390,
    double scale = 1.0,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [productProvider(detail.slug).overrideWith((ref) => detail)],
        child: MaterialApp(
          theme: AppTheme.light(),
          builder: (context, inner) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: inner!,
          ),
          home: ProductScreen(slug: detail.slug),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('the number is an icon alone beside the enquiry button', (tester) async {
    await pump(
      tester,
      ShopProductDetail(
        slug: product.slug,
        name: product.name,
        priceLabel: product.priceLabel,
        canEnquire: true,
        canCall: true,
      ),
    );

    expect(find.text('Their number'), findsNothing);
    expect(find.byIcon(Icons.call_outlined), findsOneWidget);

    // The one people came for keeps its words.
    expect(find.text('Ask about this'), findsOneWidget);
  });

  /// An icon with no words beside it is nothing at all to a screen reader.
  testWidgets('the icon still says what it is', (tester) async {
    await pump(
      tester,
      ShopProductDetail(
        slug: product.slug,
        name: product.name,
        priceLabel: product.priceLabel,
        canEnquire: true,
        canCall: true,
      ),
    );

    expect(
      find.bySemanticsLabel('Their number'),
      findsOneWidget,
      reason: 'the handset has no accessible name',
    );
  });

  /// Possible when nothing would receive an enquiry — no maker email and no
  /// contact address in Settings. An unlabelled handset alone in an otherwise
  /// empty bar explains nothing, and then it is the only thing on offer.
  testWidgets('it keeps its words when it is the only button', (tester) async {
    await pump(
      tester,
      ShopProductDetail(
        slug: product.slug,
        name: product.name,
        priceLabel: product.priceLabel,
        canCall: true,
      ),
    );

    expect(find.text('Their number'), findsOneWidget);
    expect(find.text('Ask about this'), findsNothing);
  });

  /// The bar draws nothing rather than a button that would reach nobody.
  testWidgets('no flags, no bar', (tester) async {
    await pump(tester, product);

    expect(find.text('Their number'), findsNothing);
    expect(find.text('Ask about this'), findsNothing);
    expect(find.byIcon(Icons.call_outlined), findsNothing);
  });

  /// The narrowest Android still in use, at the largest font the app allows —
  /// the size that caught the app bar overflowing by 133px.
  testWidgets('it fits a small phone at the largest font', (tester) async {
    await pump(
      tester,
      ShopProductDetail(
        slug: product.slug,
        name: product.name,
        priceLabel: product.priceLabel,
        canEnquire: true,
        canCall: true,
      ),
      width: 320,
      scale: 1.3,
    );

    expect(tester.takeException(), isNull, reason: 'the contact bar overflowed');
  });
}
