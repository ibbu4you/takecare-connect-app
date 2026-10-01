library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/home.dart';
import '../../core/router/route_names.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/tcif_logo.dart';
import 'sections/hero_carousel.dart';
import 'sections/landing_bands.dart';
import 'sections/stories_band.dart';

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
          child: StoriesBand(featured: data.featuredStories, sections: data.categorySections),
        ),

      if (data.featuredProducts.isNotEmpty) ShopBand(products: data.featuredProducts),

      const EventsBand(),

      if (data.activeCampaigns.isNotEmpty) CampaignsBand(campaigns: data.activeCampaigns),

      const ApproachBand(),

      const EcosystemBand(),

      if (images.vision != null) VisionBand(image: images.vision!),

      const FitInBand(),

      const ClosingBand(),
    ];

    return [for (final band in bands) SliverToBoxAdapter(child: band)];
  }
}

/// The app bar, extracted so the fit test can pump the real thing.
///
/// test/app_bar_fit_test.dart used to keep its own copy of this and said so in
/// its own comment — a duplicate that could drift from what ships is a test
/// asserting the wrong widget fits.
SliverAppBar homeAppBar(BuildContext context) {
  return SliverAppBar(
    // Floating and snapping, so search is one flick away from anywhere down
    // the page rather than a scroll back to the top.
    floating: true,
    snap: true,
    backgroundColor: AppColors.background,
    surfaceTintColor: AppColors.background,
    // The logo goes in `leading`, not into a Row inside `title`.
    //
    // This started as a logo beside a two-line block holding both the app's
    // name and the foundation's full name, packed into the title slot. It
    // overflowed on a real phone. Replacing the block with a single Flexible
    // line should have been enough — and by every measurement it is, at every
    // width from 320pt up — but a hand-built Row in the title slot competes
    // with the leading gap and the actions for a width it is never told, which
    // is why it went wrong twice.
    //
    // AppBar already has a slot that is measured for it. Using it means there
    // is no Flex here at all, and so nothing that can overflow.
    //
    // Nothing is lost by dropping the second line: the full name and the
    // tagline are both on the More tab, under the same mark.
    leadingWidth: 58,
    leading: const Padding(
      padding: EdgeInsets.only(left: 16),
      child: Center(child: TcifLogo(size: 30)),
    ),
    titleSpacing: 10,
    title: Text(
      'Takecare Connect',
      style: AppText.title.copyWith(fontSize: 17),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    actions: [
      IconButton(
        onPressed: () => context.push(Routes.search),
        icon: const Icon(Icons.search_rounded),
        tooltip: 'Search',
      ),
    ],
  );
}
