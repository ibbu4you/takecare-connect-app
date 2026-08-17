import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/home.dart';
import '../../core/router/route_names.dart';
import '../../core/router/web_paths.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/tcif_logo.dart';

/// The front page: banner carousel, featured stories, craftsmen, campaigns,
/// programmes, and whatever category rails the office has arranged.
///
/// Every section comes from a single `/home` request, composed server-side, so
/// this screen has one loading state rather than six.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider);

    return Scaffold(
      appBar: AppBar(
        // The logo goes in `leading`, not into a Row inside `title`.
        //
        // This started as a logo beside a two-line block holding both the app's
        // name and the foundation's full name, packed into the title slot. It
        // overflowed on a real phone. Replacing the block with a single
        // Flexible line should have been enough — and by every measurement it
        // is, at every width from 320pt up — but a hand-built Row in the title
        // slot competes with the leading gap and the actions for a width it is
        // never told, which is why it went wrong twice.
        //
        // AppBar already has a slot that is measured for it. Using it means
        // there is no Flex here at all, and so nothing that can overflow.
        // test/app_bar_fit_test.dart holds it to that.
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
            onPressed: () => context.push('${Routes.home}search'),
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(homeProvider.future),
        child: home.when(
          loading: () => const _Scrollable(child: LoadingView(height: 420)),
          error: (error, _) => _Scrollable(
            child: ErrorView(error: error, onRetry: () => ref.invalidate(homeProvider)),
          ),
          data: (data) => _HomeBody(data: data),
        ),
      ),
    );
  }
}

/// Keeps the loading and error states pullable-to-refresh.
class _Scrollable extends StatelessWidget {
  const _Scrollable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [const SizedBox(height: 60), child],
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.data});

  final HomePayload data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        if (data.banners.isNotEmpty) BannerCarousel(banners: data.banners),

        // The donate call sits above everything editorial. It is the reason
        // the foundation is asking for a reader's attention at all.
        const _DonateStrip(),

        if (data.activeCampaigns.isNotEmpty) ...[
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
              itemCount: data.activeCampaigns.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final campaign = data.activeCampaigns[i];

                return CampaignCard(
                  campaign: campaign,
                  width: 280,
                  onTap: () => context.go(Routes.campaign(campaign.slug)),
                );
              },
            ),
          ),
        ],

        if (data.featuredStories.isNotEmpty) ...[
          SectionHeader(
            eyebrow: 'From the field',
            title: 'Latest stories',
            actionLabel: 'All',
            onAction: () => context.go(Routes.stories),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (final post in data.featuredStories.take(4)) ...[
                  PostCard(post: post, onTap: () => context.go(Routes.story(post.slug))),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],

        if (data.featuredCraftsmen.isNotEmpty) ...[
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
              itemCount: data.featuredCraftsmen.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final business = data.featuredCraftsmen[i];

                return BusinessTile(
                  business: business,
                  onTap: () => context.go(Routes.craftsman(business.slug)),
                );
              },
            ),
          ),
        ],

        if (data.programmes.isNotEmpty) ...[
          const SectionHeader(eyebrow: 'What we do', title: 'Our programmes'),
          _Programmes(programmes: data.programmes),
        ],

        // The editorially-arranged rails, in whatever order the office set.
        for (final section in data.categorySections)
          if (section.posts.isNotEmpty) ...[
            SectionHeader(
              title: section.name,
              description: section.description,
              actionLabel: 'More',
              onAction: () => context.go('${Routes.stories}?category=${section.slug}'),
            ),
            SizedBox(
              height: 288,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: section.posts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final post = section.posts[i];

                  return PostTile(
                    post: post,
                    onTap: () => context.go(Routes.story(post.slug)),
                  );
                },
              ),
            ),
          ],
      ],
    );
  }
}

/// The hero carousel.
///
/// Swipe-driven, with dots. Auto-advance is deliberately gentle — six seconds,
/// and it stops for good the moment the reader swipes, because a banner that
/// keeps moving under somebody reading it is an argument, not a feature.
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key, required this.banners});

  final List<BannerSlide> banners;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();

    if (widget.banners.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 6), (_) {
        if (!mounted || !_controller.hasClients) return;

        final next = (_index + 1) % widget.banners.length;
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _stopAutoplay() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          // Portrait-ish, because the banners carry designed artwork that a
          // 16:9 letterbox would crop the words out of.
          aspectRatio: 4 / 3,
          child: NotificationListener<ScrollStartNotification>(
            onNotification: (_) {
              _stopAutoplay();

              return false;
            },
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.banners.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => _Banner(slide: widget.banners[i]),
            ),
          ),
        ),
        if (widget.banners.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.banners.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: i == _index ? 20 : 6,
                    decoration: BoxDecoration(
                      color: i == _index ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.slide});

  final BannerSlide slide;

  Future<void> _open(BuildContext context) => openWebPath(context, slide.ctaUrl);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppImage(url: slide.bestImage, fit: BoxFit.cover, semanticLabel: slide.title),

          // A banner whose artwork already carries its words gets no scrim and
          // no overlaid copy — printing the title again over the top of a
          // designed poster is how the website used to look wrong.
          if (!slide.isImageOnly) ...[
            // The scrim has to be dark enough, high enough, that white copy is
            // legible over *any* photograph — including a pale one, and
            // including the placeholder that shows while the image is still
            // arriving. The first pass faded in only over the bottom third and
            // left a three-line white headline sitting on near-white sky.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x330B1020),
                    Color(0x8A0B1020),
                    Color(0xF20B1020),
                  ],
                  stops: [0, 0.45, 1],
                ),
              ),
              child: SizedBox.expand(),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (slide.eyebrow != null && slide.eyebrow!.isNotEmpty)
                    Text(slide.eyebrow!.toUpperCase(), style: AppText.eyebrow),
                  if (slide.title != null && slide.title!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      slide.title!,
                      style: AppText.h1.copyWith(color: Colors.white, fontSize: 23),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (slide.subtitle != null && slide.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      slide.subtitle!,
                      // Near-white, not the footer's muted blue-grey: that tone
                      // is legible on a flat navy band and disappears against a
                      // photograph.
                      style: AppText.excerpt.copyWith(color: const Color(0xE6FFFFFF)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (slide.ctaLabel != null && slide.ctaLabel!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: () => _open(context),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 42),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                      ),
                      child: Text(slide.ctaLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The standing donate call under the carousel.
class _DonateStrip extends StatelessWidget {
  const _DonateStrip();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Stand behind a maker', style: AppText.h3.copyWith(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    'Every rupee is receipted and reported. 80G tax benefit applies.',
                    style: AppText.meta,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () => context.go(Routes.donate),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentButton,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              child: const Text('Donate'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Programmes extends StatelessWidget {
  const _Programmes({required this.programmes});

  final List<Programme> programmes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final programme in programmes) ...[
            AppCard(
              padding: const EdgeInsets.all(14),
              // Through the translator, never straight to `context.go`. These
              // paths are the website's — `/blog/category/tales-of-brands`,
              // `/interview-today` — and three of the four programme cards
              // landed on the "page has moved" screen when they were passed
              // through unchanged.
              onTap: programme.path.isEmpty
                  ? null
                  : () => openWebPath(context, programme.path),
              child: Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.small),
                    ),
                    child: const Icon(
                      Icons.volunteer_activism_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(programme.title, style: AppText.title.copyWith(fontSize: 15)),
                        if (programme.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            programme.description,
                            style: AppText.meta,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (programme.path.isNotEmpty)
                    Icon(
                      // An external programme leaves the app; say so.
                      programme.external
                          ? Icons.open_in_new_rounded
                          : Icons.chevron_right_rounded,
                      size: programme.external ? 16 : 24,
                      color: AppColors.mutedForeground,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
