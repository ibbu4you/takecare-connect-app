import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takecare_connect/core/models/home.dart';
import 'package:takecare_connect/features/home/sections/hero_carousel.dart';

/// The hero, shortened to 440, still holds a full slide.
///
/// The longest copy the office is likely to write, both buttons, and the
/// controls row, on the narrowest phone at the largest text the app allows.
void main() {
  final slide = BannerSlide.fromJson(const {
    'eyebrow': 'Registered Indian NGO',
    'title': 'We tell the stories of India’s small businesses — and help fund them',
    'subtitle': 'We interview self-employed founders in their workshops, publish what they make '
        'and how they make it, and run transparent crowdfunding campaigns for the equipment '
        'that lets them grow.',
    'cta': {'label': 'Meet the craftsmen', 'url': '/craftsmen'},
    'secondary_cta': {'label': 'See active campaigns', 'url': '/campaigns'},
  });

  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('a full slide fits at ${width.toInt()}pt and ${scale}x', (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, inner) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
              child: inner!,
            ),
            home: Scaffold(body: ListView(children: [BannerCarousel(banners: [slide, slide])])),
          ),
        );
        await tester.pump();

        expect(tester.getSize(find.byType(BannerCarousel)).height, BannerCarousel.height);
        expect(find.text('Meet the craftsmen'), findsWidgets);
        expect(find.text('See active campaigns'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
