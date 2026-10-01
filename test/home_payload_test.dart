import 'package:flutter_test/flutter_test.dart';
import 'package:takecare_connect/core/models/home.dart';
import 'package:takecare_connect/core/models/shop.dart';
import 'package:takecare_connect/core/models/site.dart';

/// What the app does when the server is older than it is.
///
/// This is the file that keeps the two releases independent. Every band added
/// to the home screen — the subjects, the impact figures, the quote, the two
/// invitation photographs, the footer strip — arrived in the API after 1.0.1
/// shipped, and a build pointed at a site that has not been deployed yet must
/// draw what it can and leave the rest out. Not throw, and not render an empty
/// heading.
///
/// It is also the reverse guard: a key the server sends and the app has not
/// been taught is ignored rather than fatal.
void main() {
  group('a home payload from an older server', () {
    test('parses with nothing but banners', () {
      final payload = HomePayload.fromJson({
        'banners': [
          {'title': 'A weaver in Bhuj', 'image': 'https://example.test/a.jpg'},
        ],
      });

      expect(payload.banners, hasLength(1));
      // The landing page's newer sections, from a server that predates them:
      // empty, and the sections leave themselves out.
      expect(payload.featuredProducts, isEmpty);
      expect(payload.landingImages.whoWeAre, isNull);
      expect(payload.landingImages.vision, isNull);
      expect(payload.footerBanner, isNull);
    });

    test('parses from an entirely empty object', () {
      final payload = HomePayload.fromJson(const {});

      expect(payload.banners, isEmpty);
      expect(payload.categorySections, isEmpty);
      expect(payload.activeCampaigns, isEmpty);
    });

    /// The scrim every banner wore before the office could choose one.
    test('a banner with no overlay gets the standard scrim', () {
      final slide = BannerSlide.fromJson(const {'title': 'Untinted'});

      expect(slide.overlay, BannerOverlay.standard);
      expect(slide.hasSecondaryCta, isFalse);
    });

    test('an unrecognised overlay falls back rather than throwing', () {
      expect(
        BannerSlide.fromJson(const {'overlay': 'lavender'}).overlay,
        BannerOverlay.standard,
      );
    });
  });

  group('a home payload from the current server', () {
    test('carries every band', () {
      final payload = HomePayload.fromJson({
        'banners': [
          {
            'title': 'Hero',
            'image': 'https://example.test/hero.jpg',
            'image_alt': 'A loom in a workshop',
            'overlay': 'heavy',
            'cta': {'label': 'Read it', 'url': '/blog/a-weaver'},
            'secondary_cta': {'label': 'All stories', 'url': '/blog'},
          },
        ],
        'featured_products': [
          {'slug': 'noni-soap', 'name': 'Eden Noni Soap', 'price_label': '₹100'},
        ],
        'featured_craftsmen': [
          {'slug': 'eden', 'name': 'Eden Food Park', 'headline': 'The inspiring journey of Abdullah'},
          {'slug': 'plain', 'name': 'A maker with no interview headline'},
        ],
        'landing_images': {
          'who_we_are': 'https://example.test/who.webp',
          'pillars': {'craftsmanship': 'c.webp', 'events': 'e.webp', 'crowdfunding': 'f.webp', 'stories': 's.webp'},
          'vision': 'https://example.test/vision.png',
        },
        'footer_banner': {'title': 'Above the footer', 'image': 'strip.jpg'},
      });

      final slide = payload.banners.first;
      expect(slide.overlay, BannerOverlay.heavy);
      expect(slide.semanticLabel, 'A loom in a workshop');
      expect(slide.hasCta, isTrue);
      expect(slide.hasSecondaryCta, isTrue);

      expect(payload.featuredProducts.single.name, 'Eden Noni Soap');

      // A maker card is titled with the interview headline, or the name.
      expect(payload.featuredCraftsmen.first.title, 'The inspiring journey of Abdullah');
      expect(payload.featuredCraftsmen.last.title, 'A maker with no interview headline');

      expect(payload.landingImages.whoWeAre, 'https://example.test/who.webp');
      expect(payload.landingImages.events, 'e.webp');
      expect(payload.landingImages.vision, 'https://example.test/vision.png');
      expect(payload.footerBanner?.title, 'Above the footer');
    });
  });

  group('the shop', () {
    /// "Ask the maker" is the foundation's phrase, decided on the server. The
    /// fallback here is the same words, so a payload that somehow arrives
    /// without one cannot invent a different phrase for an absent price.
    test('a product with no price label falls back to the foundation wording', () {
      final product = ShopProduct.fromJson(const {'slug': 'bowl', 'name': 'Bowl'});

      expect(product.priceLabel, 'Ask the maker');
      expect(product.aiAssisted, isFalse);
      expect(product.maker, isNull);
    });

    test('a product carries its maker and its AI note', () {
      final product = ShopProduct.fromJson(const {
        'slug': 'blue-bowl',
        'name': 'Blue serving bowl',
        'price_label': '₹450 / piece',
        'ai_assisted': true,
        'maker': {'slug': 'selvi-pottery', 'name': 'Selvi Pottery', 'city': 'Khurja'},
      });

      expect(product.priceLabel, '₹450 / piece');
      expect(product.aiAssisted, isTrue);
      expect(product.maker!.label, 'Selvi Pottery, Khurja');
    });

    /// Both flags default to false on a detail payload: a product page that
    /// cannot tell whether an enquiry would reach anybody must not draw the
    /// button, because the form would have nowhere to go.
    test('a product with no contact flags offers no buttons', () {
      final product = ShopProductDetail.fromJson(const {'slug': 'bowl', 'name': 'Bowl'});

      expect(product.canEnquire, isFalse);
      expect(product.canCall, isFalse);
      expect(product.anyAiAssisted, isFalse);
    });

    test('a maker with no city reads as just their name', () {
      final maker = MakerRef.fromJson(const {'slug': 'x', 'name': 'Assam Cane'});

      expect(maker!.label, 'Assam Cane');
    });

    test('a brand falls back through logo, photograph and banner for its mark', () {
      expect(
        Brand.fromJson(const {'slug': 'a', 'name': 'A', 'image': 'photo.jpg'}).mark,
        'photo.jpg',
      );
      expect(
        Brand.fromJson(const {'slug': 'a', 'name': 'A', 'logo': 'logo.jpg', 'image': 'p.jpg'}).mark,
        'logo.jpg',
      );
      expect(Brand.fromJson(const {'slug': 'a', 'name': 'A'}).mark, isNull);
    });

    test('a maker with no published interview offers none', () {
      final brand = Brand.fromJson(const {'slug': 'a', 'name': 'A'});

      expect(brand.hasInterview, isFalse);
    });
  });

  group('settings', () {
    /// The app must not offer a payment path that cannot complete, so an older
    /// server saying nothing means no.
    test('international donations are closed unless the server says otherwise', () {
      expect(SiteSettings.fromJson(const {}).internationalDonationsEnabled, isFalse);
      expect(
        SiteSettings.fromJson(const {
          'donations': {'international_enabled': true},
        }).internationalDonationsEnabled,
        isTrue,
      );
    });

    test('the store links are absent until the office fills them in', () {
      expect(SiteSettings.fromJson(const {}).playUrl, isNull);
      expect(
        SiteSettings.fromJson(const {
          'app': {'play': 'https://play.example/app'},
        }).playUrl,
        'https://play.example/app',
      );
    });
  });

  group('membership', () {
    test('a free plan says Free rather than ₹0', () {
      final plan = MembershipPlan.fromJson(const {'name': 'Starter', 'amount': 0, 'isFree': true});

      expect(plan.priceLabel, 'Free');
    });

    test('a yearly plan says so in words', () {
      final plan = MembershipPlan.fromJson(const {
        'name': 'Yearly',
        'amount': 1200,
        'months': 12,
      });

      expect(plan.priceLabel, '₹1200 a year');
    });

    test('an empty payload still has a title', () {
      expect(MembershipContent.fromJson(const {}).title, 'Membership for craftsmen');
    });
  });
}
