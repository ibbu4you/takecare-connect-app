library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/home.dart';
import '../../core/router/route_names.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/site_menu.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/tcif_logo.dart';
import 'sections/hero_carousel.dart';
import 'sections/landing_bands.dart';
import 'sections/landing_footer.dart';
import 'sections/landing_rows.dart';

/// The front page, matching the website's landing page section for section.
///
/// Read off the website's resources/js/Pages/Home.tsx, in its order and with its
/// words: hero, who we are, the four pillars, meet the makers, the stories, the
/// shop, events, crowdfunding, our approach, our ecosystem, our vision, where do
/// you fit in, and the closing ask.
///
/// One section of the website's is left out on purpose — "in your pocket", the
/// app store badges — because somebody reading this already has the app.
///
/// Everything still comes from one `/home` request. The sections drawn from the
/// office's content (makers, stories, shop, campaigns) hide themselves when
/// there is nothing to show, as the website's do; the written ones always show.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider);

    return Scaffold(
      // The website's ☰ menu, from the right, where its button is.
      endDrawer: SiteMenu(host: context),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(homeProvider.future),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            homeAppBar(context),
            ...home.when(
              loading: () => const [
                SliverToBoxAdapter(child: LoadingView(height: 420)),
              ],
              error: (error, _) => [
                SliverToBoxAdapter(
                  child: ErrorView(error: error, onRetry: () => ref.invalidate(homeProvider)),
                ),
              ],
              data: (data) => _bands(context, data),
            ),
          ],
        ),
      ),
    );
  }

  /// The page, section by section.
  ///
  /// A flat list of slivers rather than nested scrollables: the rails inside
  /// some sections scroll sideways, and wrapping the lot in a ListView would
  /// put a second vertical scrollable inside the first.
  List<Widget> _bands(BuildContext context, HomePayload data) {
    final images = data.landingImages;

    final bands = <Widget>[
      if (data.banners.isNotEmpty) BannerCarousel(banners: data.banners) else const FallbackHero(),

      WhoWeAreBand(image: images.whoWeAre),

      PillarsBand(images: images),

      if (data.featuredCraftsmen.isNotEmpty) MakersBand(businesses: data.featuredCraftsmen),

      if (data.featuredStories.length > 1)
        HomeBand(
          ground: BandGround.surface,
          child: LandingStoriesBand(featured: data.featuredStories, sections: data.categorySections),
        ),

      if (data.featuredProducts.isNotEmpty) ShopBand(products: data.featuredProducts),

      const EventsBand(),

      if (data.activeCampaigns.isNotEmpty) CampaignsBand(campaigns: data.activeCampaigns),

      const ApproachBand(),

      const EcosystemBand(),

      if (images.vision != null) VisionBand(image: images.vision!),

      const FitInBand(),

      const ClosingBand(),

      // The strip the office sets above the website's footer. The footer
      // itself is left out of the app: the tabs and the menu carry its links.
      if (data.footerBanner != null) FooterBannerBand(banner: data.footerBanner!),
    ];

    return [for (final band in bands) SliverToBoxAdapter(child: band)];
  }
}

/// The app bar, extracted so the fit test can pump the real thing.
///
/// The shop draws it too, because on the website the shop is under the same
/// header as the home page.
///
/// test/app_bar_fit_test.dart used to keep its own copy of this and said so in
/// its own comment — a duplicate that could drift from what ships is a test
/// asserting the wrong widget fits.
SliverAppBar homeAppBar(BuildContext context) {
  /*
   | The website's header, as it is on a phone: the mark on the left, and a red
   | Donate button and the ☰ on the right. Nothing in between — the website
   | has no words there either, and the mark says whose site it is.
   |
   | Search, which sat here, is the first row of the menu now. The website
   | keeps it out of its header, and a third control in a bar this width is
   | the thing that overflowed it before.
   */
  return SliverAppBar(
    // Floating and snapping, so the menu is one flick away from anywhere down
    // the page rather than a scroll back to the top.
    floating: true,
    snap: true,
    backgroundColor: AppColors.background,
    surfaceTintColor: AppColors.background,
    automaticallyImplyLeading: false,
    leadingWidth: 64,
    leading: const Padding(
      padding: EdgeInsets.only(left: 16),
      child: Center(child: TcifLogo(size: 40)),
    ),
    actions: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: FilledButton(
          onPressed: () => context.push(Routes.donate),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.accentForeground,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            minimumSize: const Size(0, 36),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.field)),
          ),
          child: Text('Donate', style: AppText.button),
        ),
      ),
      const SizedBox(width: 4),
      // A Builder, because the Scaffold that owns the menu is below the
      // context this bar is built from, and Scaffold.of has to look up from
      // somewhere inside it.
      Builder(
        builder: (inner) => IconButton(
          onPressed: () => Scaffold.of(inner).openEndDrawer(),
          icon: const Icon(Icons.menu_rounded),
          tooltip: 'Open menu',
        ),
      ),
      const SizedBox(width: 6),
    ],
  );
}
