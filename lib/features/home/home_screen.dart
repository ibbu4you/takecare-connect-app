library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/business.dart';
import '../../core/models/campaign.dart';
import '../../core/models/home.dart';
import '../../core/router/route_names.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/tcif_logo.dart';
import 'sections/category_tiles.dart';
import 'sections/hero_carousel.dart';
import 'sections/impact_band.dart';
import 'sections/promo_panels.dart';
import 'sections/stories_band.dart';

/// The front page.
///
/// The bands are in the website's order, read off its Home.tsx rather than
/// guessed: hero, the subjects, the impact band, the stories, the craftsmen,
/// the two invitations, the programmes, the campaigns, and the footer strip.
///
/// Every section comes from a single `/home` request, composed server-side, so
/// this screen has one loading state rather than nine — and every band hides
/// itself when the office has not filled it in, so an empty section is never a
/// heading over nothing.
///
/// Two deliberate departures from the web page, because a phone is not a
/// browser. The app store badges are dropped — a badge for the store you were
/// installed from — and the footer strip appears here and on More rather than
/// under every screen, because a promotional band under every article is where
/// people stop scrolling.
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

  /// The page, band by band.
  ///
  /// A flat list of slivers rather than nested scrollables: the rails inside
  /// each band scroll horizontally, and wrapping the lot in a ListView would
  /// mean a second vertical scrollable inside the first.
  List<Widget> _bands(BuildContext context, HomePayload data) {
    final bands = <Widget>[
      if (data.banners.isNotEmpty) BannerCarousel(banners: data.banners),

      // Directly under the hero: the first question a reader has is what is
      // here, and a list of subjects answers it better than a band of prose.
      if (data.postCategories.isNotEmpty)
        _Band(child: CategoryTiles(categories: data.postCategories)),

      // The figures, the quote and the invitation, in one band. This is where
      // the donate ask lives — the website folded the two together, and an
      // earlier version of this screen had a hand-written donate strip with
      // invented copy sitting above everything editorial instead.
      if (data.stats.isNotEmpty || data.testimonials.isNotEmpty)
        ImpactBand(
          stats: data.stats,
          testimonials: data.testimonials,
          image: data.ctaImage,
        ),

      if (data.featuredStories.length > 1)
        _Band(
          surface: true,
          child: StoriesBand(
            featured: data.featuredStories,
            sections: data.categorySections,
          ),
        ),

      // Directly under the stories, and in the same shape. Reading about the
      // work and meeting whoever did it are the same errand.
      if (data.featuredCraftsmen.isNotEmpty)
        _Band(child: _CraftsmenRail(businesses: data.featuredCraftsmen)),

      _Band(surface: true, child: PromoPanels(images: data.promoImages)),

      if (data.programmes.isNotEmpty)
        _Band(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(eyebrow: 'What we do', title: 'Our programmes'),
              ProgrammesBand(programmes: data.programmes),
            ],
          ),
        ),

      // Its own band near the foot, as on the website. The ask is already at
      // band three, so there is nothing to rescue by moving this up.
      if (data.activeCampaigns.isNotEmpty)
        _Band(surface: true, child: _CampaignsRail(campaigns: data.activeCampaigns)),

      if (data.footerBanner != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.card),
            child: BannerFrame(slide: data.footerBanner!, aspectRatio: 16 / 9),
          ),
        ),

      const SizedBox(height: 28),
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

/// One band's padding and ground.
///
/// White and `surface` alternate down the page, which is how the website
/// carries its section rhythm — borders and a change of ground rather than
/// shadows.
class _Band extends StatelessWidget {
  const _Band({required this.child, this.surface = false});

  final Widget child;
  final bool surface;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: surface ? AppColors.surface : AppColors.background,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: child,
      ),
    );
  }
}

class _CraftsmenRail extends StatelessWidget {
  const _CraftsmenRail({required this.businesses});

  final List<BusinessSummary> businesses;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          eyebrow: 'The people',
          title: 'Craftsmen and makers',
          description: 'Interviews with the artisans the foundation works alongside.',
          actionLabel: 'All',
          onAction: () => context.go(Routes.craftsmen),
        ),
        SizedBox(
          height: 264,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: businesses.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final business = businesses[i];

              return BusinessTile(
                business: business,
                onTap: () => context.go(Routes.craftsman(business.slug)),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CampaignsRail extends StatelessWidget {
  const _CampaignsRail({required this.campaigns});

  final List<Campaign> campaigns;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          eyebrow: 'Open appeals',
          title: 'Campaigns you can back',
          actionLabel: 'All',
          onAction: () => context.go(Routes.give),
        ),
        SizedBox(
          height: 340,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: campaigns.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final campaign = campaigns[i];

              return CampaignCard(
                campaign: campaign,
                width: 280,
                onTap: () => context.go(Routes.campaign(campaign.slug)),
              );
            },
          ),
        ),
      ],
    );
  }
}
