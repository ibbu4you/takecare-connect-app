library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/business.dart';
import '../../../core/models/campaign.dart';
import '../../../core/models/home.dart';
import '../../../core/models/shop.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/card_carousel.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/shop_cards.dart';

/*
 | The landing page's sections, as the website draws them on a phone.
 |
 | Read off resources/js/Pages/Home.tsx on the website and kept in its order,
 | with its words. Where the website lays a row of cards side by side on a
 | desktop, it stacks them on a phone, and so do these — the app is meant to
 | look like the website does in a phone's browser, not like a second design.
 |
 | The words are written in here, as they are in Home.tsx. Change one and the
 | other should change with it; nothing checks that they agree.
 */

/// The ground a section sits on: white, the grey surface, or navy.
enum BandGround { white, surface, navy, navyDeep }

/// One section's ground and spacing.
///
/// The website alternates white, grey and navy down the page and separates
/// them by the change of colour alone; this does the same.
class HomeBand extends StatelessWidget {
  const HomeBand({
    super.key,
    required this.child,
    this.ground = BandGround.white,
    this.padding = const EdgeInsets.symmetric(vertical: 32),
  });

  final Widget child;
  final BandGround ground;
  final EdgeInsets padding;

  static Color colourOf(BandGround ground) => switch (ground) {
        BandGround.white => AppColors.background,
        BandGround.surface => AppColors.surface,
        BandGround.navy => AppColors.primary,
        BandGround.navyDeep => AppColors.primaryDark,
      };

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: colourOf(ground),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// The eyebrow, heading and line every section opens with, stacked and left.
///
/// The "view all" link goes on its own line under them, not beside the
/// heading. Beside it, "View all craftsmen" took half a phone's width and left
/// the heading a sliver to wrap in a word at a time — which is why the website
/// moves it under the heading on a phone too.
Widget _header({
  required String eyebrow,
  required String title,
  String? description,
  String? actionLabel,
  VoidCallback? onAction,
  bool onDark = false,
}) {
  final heading = SectionHeader(
    eyebrow: eyebrow,
    title: title,
    description: description,
    onDark: onDark,
    padding: EdgeInsets.fromLTRB(16, 0, 16, actionLabel == null ? 20 : 10),
  );

  if (actionLabel == null || onAction == null) return heading;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      heading,
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: InkWell(
          onTap: onAction,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _ArrowLink(
              label: actionLabel,
              colour: onDark ? AppColors.primaryForeground : AppColors.primary,
            ),
          ),
        ),
      ),
    ],
  );
}

/// A link with an arrow after it: "Read their story →".
class _ArrowLink extends StatelessWidget {
  const _ArrowLink({required this.label, this.colour = AppColors.primary});

  final String label;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            style: AppText.bodyStrong.copyWith(fontSize: 14, color: colour),
          ),
        ),
        const SizedBox(width: 6),
        Icon(Icons.arrow_forward_rounded, size: 16, color: colour),
      ],
    );
  }
}

/// The red button the website uses for its two strongest calls.
///
/// accentButton, the darker red, rather than the accent itself: white on the
/// lighter red does not reach the contrast a label needs.
class _AccentButton extends StatelessWidget {
  const _AccentButton({required this.label, required this.onPressed, this.expand = false});

  final String label;
  final VoidCallback onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accentButton,
        foregroundColor: AppColors.accentForeground,
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.field)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(label, style: AppText.button)),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded, size: 18),
        ],
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// "01", "02" — the website's padded numerals.
String _numeral(int index) => (index + 1).toString().padLeft(2, '0');

// ===================================================================== hero ===

/// Shown when the office has set no banner, so the page still says what it is.
class FallbackHero extends StatelessWidget {
  const FallbackHero({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeBand(
      ground: BandGround.navy,
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, size: 14, color: AppColors.primaryForeground),
                const SizedBox(width: 6),
                // Flexible, so the line can wrap: at its letter-spacing it is
                // wider than a 390pt phone has room for beside the icon.
                Flexible(
                  child: Text(
                    'REAL PEOPLE. REAL STORIES.',
                    style: AppText.eyebrow.copyWith(color: AppColors.primaryForeground),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text.rich(
            const TextSpan(
              children: [
                TextSpan(text: 'Talent is everywhere.\n'),
                TextSpan(
                  text: 'Opportunity isn’t.',
                  style: TextStyle(color: AppColors.accent),
                ),
              ],
            ),
            style: AppText.h1.copyWith(color: AppColors.primaryForeground),
          ),
          const SizedBox(height: 14),
          Text(
            'We publish the stories of India’s self-employed founders and small businesses, '
            'and raise money for them in the open.',
            style: AppText.body.copyWith(
              color: AppColors.primaryForeground.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: () => context.go(Routes.stories),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryForeground,
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(0, 48),
                ),
                child: Text('Explore stories', style: AppText.button),
              ),
              OutlinedButton(
                onPressed: () => context.go(Routes.registerInterview),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryForeground,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                  minimumSize: const Size(0, 48),
                ),
                child: Text('Share your story', style: AppText.button),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================== who we are ===

class WhoWeAreBand extends StatelessWidget {
  const WhoWeAreBand({super.key, this.image});

  final String? image;

  @override
  Widget build(BuildContext context) {
    final strong = AppText.lead.copyWith(fontWeight: FontWeight.w600, color: AppColors.foreground);
    final soft = AppText.lead.copyWith(color: AppColors.mutedForeground);

    return HomeBand(
      ground: BandGround.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WHO WE ARE', style: AppText.eyebrow),
            const SizedBox(height: 6),
            Text('Connecting talent to opportunity', style: AppText.h2),
            const SizedBox(height: 18),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Across India, people create, craft, perform, build, innovate and '
                        'contribute every day. Yet too much talent remains ',
                  ),
                  TextSpan(text: 'unseen', style: strong),
                  const TextSpan(text: ', '),
                  TextSpan(text: 'undervalued', style: strong),
                  const TextSpan(text: ' and '),
                  TextSpan(text: 'disconnected', style: strong),
                  const TextSpan(text: '.'),
                ],
              ),
              style: soft,
            ),
            const SizedBox(height: 14),
            Text(
              'Take Care Connect brings people, stories, communities, businesses, markets and '
              'opportunities together through a connected platform.',
              style: soft,
            ),
            const SizedBox(height: 24),
            // The line the section argues towards, as a quotation: a red rule
            // down the left of a white card, square against the rule.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(left: BorderSide(color: AppColors.accent, width: 4)),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(AppRadii.card),
                  bottomRight: Radius.circular(AppRadii.card),
                ),
                boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 1))],
              ),
              child: Text(
                '“Every skill deserves a pathway to opportunity.”',
                style: AppText.h3.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _AccentButton(
              label: 'Discover our story',
              onPressed: () => context.go(Routes.about),
            ),
            if (image != null) ...[
              const SizedBox(height: 28),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.hero),
                  border: Border.all(color: AppColors.border),
                ),
                // Empty label on purpose, as on the website: it illustrates the
                // words above it rather than adding to them.
                child: AppImage(url: image, aspectRatio: 16 / 9, radius: AppRadii.hero),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ================================================================== pillars ===

class PillarsBand extends StatelessWidget {
  const PillarsBand({super.key, required this.images});

  final LandingImages images;

  @override
  Widget build(BuildContext context) {
    final pillars = [
      (
        title: 'Craftsmanship',
        description: 'Meet craftsmen and makers from across India, discover their stories and '
            'explore the products they create.',
        action: 'Explore craftsmanship',
        route: Routes.craftsmen,
        image: images.craftsmanship,
      ),
      (
        title: 'Events',
        description: 'Discover exhibitions, workshops, performances, conversations and community '
            'experiences that bring people together.',
        action: 'Explore events',
        // No events section exists; the galleries are where the events that
        // have happened live — the website points here for the same reason.
        route: Routes.galleries,
        image: images.events,
      ),
      (
        title: 'Crowdfunding',
        description: 'Discover people, ideas and initiatives seeking community support and '
            'contribute to opportunities you believe in.',
        action: 'Explore campaigns',
        route: Routes.give,
        image: images.crowdfunding,
      ),
      (
        title: 'Influencing Narratives',
        description: 'Stories that bring overlooked talent, communities, craftsmanship, ideas and '
            'initiatives into view.',
        action: 'Explore stories',
        route: Routes.stories,
        image: images.stories,
      ),
    ];

    return HomeBand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            eyebrow: 'What we do',
            title: 'Explore Take Care Connect',
            description: 'Four connected pillars bring talent, stories, experiences and '
                'opportunities into one ecosystem.',
            padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (final (index, pillar) in pillars.indexed) ...[
                  if (index > 0) const SizedBox(height: 16),
                  _PillarCard(
                    number: _numeral(index),
                    title: pillar.title,
                    description: pillar.description,
                    action: pillar.action,
                    image: pillar.image,
                    onTap: () => context.go(pillar.route),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A navy card: a photograph with its number on it, then white words.
class _PillarCard extends StatelessWidget {
  const _PillarCard({
    required this.number,
    required this.title,
    required this.description,
    required this.action,
    required this.onTap,
    this.image,
  });

  final String number;
  final String title;
  final String description;
  final String action;
  final String? image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppRadii.hero),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  color: AppColors.primaryDark,
                  child: AppImage(url: image, aspectRatio: 4 / 3),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: ExcludeSemantics(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        number,
                        style: AppText.metaStrong.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.h3.copyWith(color: AppColors.primaryForeground)),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: AppText.excerpt.copyWith(
                      color: AppColors.primaryForeground.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ArrowLink(label: action, colour: AppColors.primaryForeground),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================== makers ===

class MakersBand extends StatelessWidget {
  const MakersBand({super.key, required this.businesses});

  final List<BusinessSummary> businesses;

  @override
  Widget build(BuildContext context) {
    return HomeBand(
      ground: BandGround.navy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            onDark: true,
            eyebrow: 'Craftsmanship',
            title: 'Meet the makers',
            description: 'Every craft has a story. Every maker has a journey. Discover the people '
                'and skills behind the work.',
            actionLabel: 'View all craftsmen',
            onAction: () => context.go(Routes.craftsmen),
          ),
          CardCarousel(
            height: 352,
            itemCount: businesses.length,
            itemBuilder: (context, i) => _MakerCard(
              business: businesses[i],
              onTap: () => context.go(Routes.craftsman(businesses[i].slug)),
            ),
          ),
        ],
      ),
    );
  }
}

/// A white card on the navy: the photograph with its craft written on it, the
/// name, the person and the place, and the way in.
class _MakerCard extends StatelessWidget {
  const _MakerCard({required this.business, required this.onTap});

  final BusinessSummary business;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = [business.ownerName, business.city?.name]
        .whereType<String>()
        .where((part) => part.isNotEmpty)
        .join(' · ');

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadii.hero),
      clipBehavior: Clip.antiAlias,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AppImage(url: business.thumbnail, aspectRatio: 4 / 3, semanticLabel: business.name),
                if (business.category != null) ...[
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 12,
                    right: 16,
                    child: Text(
                      business.category!.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.eyebrow.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      // The interview's headline, as the website titles it.
                      child: Text(
                        business.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.h3,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.meta,
                      ),
                    ],
                    const Spacer(),
                    const _ArrowLink(label: 'Read their story'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================== shop ===

class ShopBand extends StatelessWidget {
  const ShopBand({super.key, required this.products});

  final List<ShopProduct> products;

  @override
  Widget build(BuildContext context) {
    return HomeBand(
      ground: BandGround.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            eyebrow: 'Shop',
            title: 'Discover the craft. Support the maker.',
            description: 'Explore products created by talented makers and craftsmen featured on '
                'Take Care Connect.',
            actionLabel: 'Visit the shop',
            onAction: () => context.go(Routes.shop),
          ),
          CardCarousel(
            height: 336,
            itemCount: products.length,
            itemBuilder: (context, i) => ProductCard(
              product: products[i],
              onTap: () => context.go(Routes.product(products[i].slug)),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================== events ===

/// Three kinds of gathering, not three dated events.
///
/// The website has no events feature — nothing with a date on it — so these say
/// what the foundation runs and claim no date, place or price, exactly as the
/// website's do. The link goes to the galleries, where past ones are.
class EventsBand extends StatelessWidget {
  const EventsBand({super.key});

  static const _strands = [
    (
      label: 'Upcoming event',
      title: 'Craft & Culture Showcase',
      description:
          'Meet makers, explore crafts and experience the stories behind traditional work.',
    ),
    (
      label: 'Workshop',
      title: 'Learn from the makers',
      description:
          'A hands-on experience connecting people with traditional skills and creative practice.',
    ),
    (
      label: 'Community',
      title: 'Stories & Conversations',
      description:
          'A space for people, ideas and perspectives to meet and create new connections.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return HomeBand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            eyebrow: 'Events',
            title: 'What is happening',
            description: 'Experiences that bring people, talent, communities and ideas together.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (final (index, strand) in _strands.indexed) ...[
                  if (index > 0) const SizedBox(height: 16),
                  AppCard(
                    onTap: () => context.go(Routes.galleries),
                    padding: const EdgeInsets.all(22),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strand.label.toUpperCase(), style: AppText.eyebrow),
                          const SizedBox(height: 6),
                          Text(strand.title, style: AppText.h3),
                          const SizedBox(height: 10),
                          Text(strand.description, style: AppText.excerpt),
                          const SizedBox(height: 18),
                          const _ArrowLink(label: 'See the photographs'),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================== campaigns ===

/// The campaigns, on the navy: three, with the way to the rest under them.
class CampaignsBand extends StatelessWidget {
  const CampaignsBand({super.key, required this.campaigns});

  final List<Campaign> campaigns;

  @override
  Widget build(BuildContext context) {
    final showing = campaigns.take(3).toList();

    return HomeBand(
      ground: BandGround.navy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            onDark: true,
            eyebrow: 'Crowdfunding',
            title: 'Ideas need opportunity',
            description: 'Discover campaigns and initiatives seeking community backing.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (index, campaign) in showing.indexed) ...[
                  if (index > 0) const SizedBox(height: 16),
                  CampaignCard(
                    campaign: campaign,
                    onTap: () => context.go(Routes.campaign(campaign.slug)),
                  ),
                ],
                if (campaigns.length > showing.length) ...[
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () => context.go(Routes.give),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: _ArrowLink(
                        label: 'All campaigns',
                        colour: AppColors.primaryForeground,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================ approach ===

/// Five steps as one panel divided, not five cards: they are one pathway.
class ApproachBand extends StatelessWidget {
  const ApproachBand({super.key});

  static const _steps = [
    (title: 'Discover', description: 'Find talent wherever it exists.'),
    (title: 'Recognise', description: 'Give skills and achievements visibility and credibility.'),
    (title: 'Connect', description: 'Bring people, organisations and opportunities together.'),
    (title: 'Empower', description: 'Create access to growth, collaboration and opportunity.'),
    (title: 'Impact', description: 'Turn opportunity into meaningful change.'),
  ];

  @override
  Widget build(BuildContext context) {
    return HomeBand(
      ground: BandGround.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            eyebrow: 'Our approach',
            title: 'From discovery to opportunity',
            description:
                'A simple pathway for making talent more visible, connected and accessible.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadii.hero),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  for (final (index, step) in _steps.indexed) ...[
                    if (index > 0) const Divider(height: 1, thickness: 1, color: AppColors.border),
                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // The numeral is for the eye; a screen reader is
                          // told the order by the order.
                          ExcludeSemantics(
                            child: SizedBox(
                              width: 44,
                              child: Text(
                                _numeral(index),
                                style: AppText.figure.copyWith(
                                  color: AppColors.accent,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(step.title, style: AppText.title),
                                const SizedBox(height: 4),
                                Text(step.description, style: AppText.excerpt),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================== ecosystem ===

class EcosystemBand extends StatelessWidget {
  const EcosystemBand({super.key});

  static const _parts = [
    (
      term: 'Talent',
      definition:
          'Creators, artisans, performers, makers, innovators, entrepreneurs and changemakers.',
    ),
    (term: 'Businesses & brands', definition: 'Markets, buyers, collaborations and CSR opportunities.'),
    (term: 'Institutions', definition: 'Education, skill development and organisations.'),
    (term: 'Government', definition: 'Schemes, programmes and institutional support.'),
    (term: 'Communities', definition: 'People, networks, mentors and support.'),
    (
      term: 'Markets & global partners',
      definition: 'Access, opportunities, shared goals and wider reach.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return HomeBand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            eyebrow: 'Our ecosystem',
            title: 'We do not replace the ecosystems. We connect them.',
            description: 'Take Care Connect brings together people and organisations that create '
                'pathways to opportunity.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (final (index, part) in _parts.indexed) ...[
                  if (index > 0) const SizedBox(height: 14),
                  AppCard(
                    padding: const EdgeInsets.all(22),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // The red hairline the website opens each one with.
                          Container(width: 40, height: 1, color: AppColors.accent),
                          const SizedBox(height: 16),
                          Text(part.term, style: AppText.h3),
                          const SizedBox(height: 6),
                          Text(part.definition, style: AppText.excerpt),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================== vision ===

/// The vision artwork, edge to edge and uncropped, as on the website.
class VisionBand extends StatelessWidget {
  const VisionBand({super.key, required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primaryDark,
      child: AppImage(
        url: image,
        // The artwork's own shape, so nothing in it is ever cut off.
        aspectRatio: 2171 / 724,
        fit: BoxFit.contain,
        semanticLabel: 'Our vision: started in Tamil Nadu, built for the world. Discovering, '
            'connecting and empowering talent across borders for a more inclusive tomorrow — '
            'from Tamil Nadu to India to global opportunity.',
      ),
    );
  }
}

// ================================================================= fit in ===

class FitInBand extends StatelessWidget {
  const FitInBand({super.key});

  @override
  Widget build(BuildContext context) {
    final doors = [
      (
        title: 'I am talent',
        description: 'Showcase your skills, work and journey.',
        action: 'Register your talent',
        route: Routes.registerInterview,
      ),
      (
        title: 'I am a business',
        description: 'Discover talent and create collaborations.',
        action: 'Partner with us',
        route: Routes.contact,
      ),
      (
        title: 'I want to support',
        description: 'Support makers, campaigns and initiatives.',
        action: 'Get involved',
        route: Routes.give,
      ),
      (
        title: 'I am an organisation',
        description: 'Connect people, programmes and opportunities.',
        action: 'Work with us',
        route: Routes.contact,
      ),
    ];

    return HomeBand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            eyebrow: 'Join our community',
            title: 'Where do you fit in?',
            description: 'Whether you create, build, support or collaborate, there is a place '
                'for you in the Take Care Connect ecosystem.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (final (index, door) in doors.indexed) ...[
                  if (index > 0) const SizedBox(height: 14),
                  Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.hero),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.go(door.route),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadii.hero),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: SizedBox(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(door.title, style: AppText.h3),
                                const SizedBox(height: 8),
                                Text(door.description, style: AppText.excerpt),
                                const SizedBox(height: 18),
                                Semantics(
                                  label: '${door.action} — ${door.title}',
                                  excludeSemantics: true,
                                  child: _ArrowLink(label: door.action),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================= closing ===

/// The closing ask: the page's largest line, two sentences, two doors.
class ClosingBand extends StatelessWidget {
  const ClosingBand({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      // White easing into the grey at the foot, as the website's does.
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.background, AppColors.background, AppColors.surface],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 56, 16, 56),
        child: Column(
          children: [
            Text(
              'Let’s build the connection together.',
              textAlign: TextAlign.center,
              style: AppText.h1.copyWith(fontSize: 32),
            ),
            const SizedBox(height: 18),
            Text(
              'A world where talent doesn’t need the right address to find the right '
              'opportunity.',
              textAlign: TextAlign.center,
              style: AppText.lead.copyWith(color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 12),
            Text(
              'Read the stories, meet the makers and back the campaigns — or tell us what you '
              'make, and we will come to you.',
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 28),
            // Both full width, so they read as two doors rather than a main
            // one and an afterthought.
            _AccentButton(
              label: 'Explore Take Care Connect',
              expand: true,
              onPressed: () => context.go(Routes.stories),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.go(Routes.contact),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.foreground,
                  backgroundColor: AppColors.background,
                  side: const BorderSide(color: AppColors.border),
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.field),
                  ),
                ),
                child: Text('Partner with us', style: AppText.button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
