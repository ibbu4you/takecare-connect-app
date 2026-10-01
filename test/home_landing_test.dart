import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takecare_connect/core/models/business.dart';
import 'package:takecare_connect/core/models/campaign.dart';
import 'package:takecare_connect/core/models/home.dart';
import 'package:takecare_connect/core/models/shop.dart';
import 'package:takecare_connect/features/home/sections/landing_bands.dart';

/// The home screen, rebuilt to match the website's landing page.
///
/// Two things are held here. The sections come in the website's order with
/// the website's headings — that order is the design, read off Home.tsx — and
/// none of them overflows on the narrowest phone at the largest text size,
/// which is where this app has broken before.
void main() {
  final maker = BusinessSummary.fromJson(const {
    'slug': 'eden-food-park',
    'name': 'Eden Food Park, maker of soaps and teas from the Nilgiris hills',
    'owner_name': 'Abdullah',
    'city': {'slug': 'ooty', 'name': 'Ooty'},
    'category': {'slug': 'food', 'name': 'Food & spices'},
  });

  final product = ShopProduct.fromJson(const {
    'slug': 'noni-soap',
    'name': 'Eden Noni Turmeric Soap with a name long enough to wrap twice',
    'price_label': '₹100',
  });

  final campaign = Campaign.fromJson(const {
    'slug': 'a-new-loom',
    'title': 'A new loom for a weaving family in Kanchipuram',
    'goal_amount': 100000,
    'raised_amount': 25000,
  });

  /// Every section, in the website's order, as HomeScreen lays them out.
  List<Widget> sections() => [
        const FallbackHero(),
        const WhoWeAreBand(),
        const PillarsBand(images: LandingImages()),
        MakersBand(businesses: [maker, maker]),
        ShopBand(products: [product, product]),
        const EventsBand(),
        CampaignsBand(campaigns: [campaign, campaign, campaign, campaign]),
        const ApproachBand(),
        const EcosystemBand(),
        const FitInBand(),
        const ClosingBand(),
      ];

  Future<void> pump(WidgetTester tester, {required Size size, double scale = 1}) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, inner) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: inner!,
        ),
        home: Scaffold(body: ListView(children: sections())),
      ),
    );
    await tester.pump();
  }

  testWidgets('the sections come in the website\'s order, with its headings', (tester) async {
    await pump(tester, size: const Size(390, 20000));

    const headings = [
      'Connecting talent to opportunity',
      'Explore Take Care Connect',
      'Meet the makers',
      'Discover the craft. Support the maker.',
      'What is happening',
      'Ideas need opportunity',
      'From discovery to opportunity',
      'We do not replace the ecosystems. We connect them.',
      'Where do you fit in?',
      'Let’s build the connection together.',
    ];

    var previous = double.negativeInfinity;

    for (final heading in headings) {
      // The first, because "Explore Take Care Connect" is both the pillars'
      // heading and the closing button's label — on the website as well.
      expect(find.text(heading), findsWidgets, reason: '"$heading" is missing');

      final top = tester.getTopLeft(find.text(heading).first).dy;
      expect(top, greaterThan(previous), reason: '"$heading" is out of the website\'s order');
      previous = top;
    }
  });

  testWidgets('the written sections carry the website\'s words', (tester) async {
    await pump(tester, size: const Size(390, 20000));

    for (final text in [
      '“Every skill deserves a pathway to opportunity.”',
      'Craftsmanship',
      'Crowdfunding',
      'Influencing Narratives',
      'Craft & Culture Showcase',
      'Recognise',
      'Markets & global partners',
      'I am an organisation',
      'Partner with us',
    ]) {
      expect(find.text(text), findsWidgets, reason: '"$text" is missing');
    }
  });

  /// Three campaigns on the page and a way to the rest, as on the website.
  testWidgets('crowdfunding shows three campaigns and links to the others', (tester) async {
    await pump(tester, size: const Size(390, 20000));

    expect(find.text('A new loom for a weaving family in Kanchipuram'), findsNWidgets(3));
    expect(find.text('All campaigns'), findsOneWidget);
  });

  for (final width in [320.0, 360.0, 390.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('nothing overflows at ${width.toInt()}pt and ${scale}x text', (tester) async {
        await pump(tester, size: Size(width, 30000), scale: scale);

        // An overflow is reported as an exception by the framework; the
        // tester collects it here rather than letting it pass silently.
        expect(tester.takeException(), isNull);
      });
    }
  }
}
