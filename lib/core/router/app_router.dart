import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/about/about_screen.dart';
import '../../features/about/page_screen.dart';
import '../../features/craftsmen/craftsman_screen.dart';
import '../../features/craftsmen/craftsmen_screen.dart';
import '../../features/forms/contact_screen.dart';
import '../../features/forms/opportunity_screen.dart';
import '../../features/forms/register_interview_screen.dart';
import '../../features/forms/sell_with_us_screen.dart';
import '../../features/give/campaign_screen.dart';
import '../../features/give/campaigns_screen.dart';
import '../../features/give/donate_result_screen.dart';
import '../../features/give/donate_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/media/galleries_screen.dart';
import '../../features/media/gallery_screen.dart';
import '../../features/media/press_screen.dart';
import '../../features/more/membership_screen.dart';
import '../../features/more/more_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/shop/brand_screen.dart';
import '../../features/shop/brands_screen.dart';
import '../../features/shop/product_screen.dart';
import '../../features/shop/shop_screen.dart';
import '../../features/stories/author_screen.dart';
import '../../features/stories/stories_screen.dart';
import '../../features/stories/story_screen.dart';
import '../theme/app_text_styles.dart';
import '../widgets/state_views.dart';
import 'app_shell.dart';
import 'route_names.dart';

final routerProvider = Provider<GoRouter>((ref) => buildRouter());

/// The app's route table.
///
/// Exposed as a function, and taking [initialLocation], for one reason: a
/// `GoRouter` cannot be re-rooted after construction, so `tool/screenshots.dart`
/// needs a fresh one per screen rather than driving navigation and waiting on
/// transitions. Everything else calls it through [routerProvider].
GoRouter buildRouter({String initialLocation = Routes.home}) {
  return GoRouter(
    // Not a file-level GlobalKey: two routers alive at once — which is exactly
    // what the screenshot tool does — would both claim it, and a GlobalKey can
    // only be attached to one element at a time.
    navigatorKey: GlobalKey<NavigatorState>(),
    initialLocation: initialLocation,
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(),
      body: EmptyView(
        title: 'That page has moved',
        subtitle: state.uri.toString(),
        icon: Icons.explore_off_rounded,
        action: FilledButton(
          onPressed: () => context.go(Routes.home),
          child: const Text('Back to the start'),
        ),
      ),
    ),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          // ------------------------------------------------------------ Home
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.home,
              builder: (context, state) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'search',
                  builder: (context, state) => const SearchScreen(),
                ),
              ],
            ),
          ]),

          // --------------------------------------------------------- Stories
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.stories,
              builder: (context, state) => StoriesScreen(
                initialCategory: state.uri.queryParameters['category'],
              ),
              routes: [
                GoRoute(
                  path: ':slug',
                  builder: (context, state) =>
                      StoryScreen(slug: state.pathParameters['slug']!),
                ),
              ],
            ),
            // Authors sit in this branch rather than their own: you always
            // arrive at one from a byline, and back should return to the story.
            GoRoute(
              path: Routes.authorDetail,
              builder: (context, state) => AuthorScreen(slug: state.pathParameters['slug']!),
            ),
          ]),

          /*
           | ------------------------------------------------------------ Shop
           |
           | Three route trees in one branch: what our makers sell, the makers
           | themselves, and the interviews with them. They share a navigator,
           | so moving from a product to its maker to the article about them
           | and back is one history rather than three.
           |
           | `/craftsmen` keeps its path. Every share link the app has produced
           | points at it, as does every `appPathFor('/businesses/...')` result
           | — only which tab owns it has changed.
           */
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.shop,
              builder: (context, state) => ShopScreen(
                initialCategory: state.uri.queryParameters['category'],
                // The Makers segment is a query, never a path segment, so a
                // product slug can never shadow it.
                initialSegment: state.uri.queryParameters['segment'],
              ),
              routes: [
                GoRoute(
                  path: ':slug',
                  builder: (context, state) =>
                      ProductScreen(slug: state.pathParameters['slug']!),
                ),
              ],
            ),
            GoRoute(
              path: Routes.craftsmen,
              builder: (context, state) => CraftsmenScreen(
                initialCategory: state.uri.queryParameters['category'],
                initialCity: state.uri.queryParameters['city'],
              ),
              routes: [
                GoRoute(
                  path: ':slug',
                  builder: (context, state) =>
                      CraftsmanScreen(slug: state.pathParameters['slug']!),
                ),
              ],
            ),
            GoRoute(
              path: Routes.brands,
              builder: (context, state) => const BrandsScreen(),
              routes: [
                GoRoute(
                  path: ':slug',
                  builder: (context, state) => BrandScreen(slug: state.pathParameters['slug']!),
                ),
              ],
            ),
          ]),

          // ------------------------------------------------------------ Give
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.give,
              builder: (context, state) => const CampaignsScreen(),
              routes: [
                GoRoute(
                  path: ':slug',
                  builder: (context, state) =>
                      CampaignScreen(slug: state.pathParameters['slug']!),
                ),
              ],
            ),
            GoRoute(
              path: Routes.donate,
              builder: (context, state) => DonateScreen(
                campaignSlug: state.uri.queryParameters['campaign'],
                campaignTitle: state.uri.queryParameters['title'],
              ),
            ),
            GoRoute(
              path: Routes.donateResult,
              builder: (context, state) => DonateResultScreen(
                reference: state.pathParameters['reference']!,
              ),
            ),
          ]),

          // ------------------------------------------------------------ More
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.more,
              builder: (context, state) => const MoreScreen(),
              routes: [
                GoRoute(
                  path: 'galleries',
                  builder: (context, state) => const GalleriesScreen(),
                  routes: [
                    GoRoute(
                      path: ':slug',
                      builder: (context, state) =>
                          GalleryScreen(slug: state.pathParameters['slug']!),
                    ),
                  ],
                ),
                GoRoute(path: 'press', builder: (context, state) => const PressScreen()),
                GoRoute(path: 'about', builder: (context, state) => const AboutScreen()),
                /*
                 | Retired, along with the website's own page.
                 |
                 | The route is kept and redirected rather than deleted: an
                 | installed 1.0.1 has this path in its More menu and in any
                 | link a reader saved, and a deleted route would land them on
                 | "that page has moved". TransparencyScreen itself is left in
                 | the tree, unreferenced — deleting this redirect and putting
                 | the builder back is the whole of bringing it back.
                 */
                GoRoute(
                  path: 'transparency',
                  redirect: (context, state) => Routes.home,
                ),
                GoRoute(path: 'contact', builder: (context, state) => const ContactScreen()),
                GoRoute(
                  path: 'membership',
                  builder: (context, state) => const MembershipScreen(),
                ),
                GoRoute(
                  path: 'sell-with-us',
                  builder: (context, state) => const SellWithUsScreen(),
                ),
                GoRoute(
                  path: 'volunteer',
                  builder: (context, state) => const OpportunityScreen(intern: false),
                ),
                GoRoute(
                  path: 'intern',
                  builder: (context, state) => const OpportunityScreen(intern: true),
                ),
                GoRoute(
                  path: 'register-interview',
                  builder: (context, state) => const RegisterInterviewScreen(),
                ),
                GoRoute(
                  path: 'pages/:slug',
                  builder: (context, state) => PageScreen(slug: state.pathParameters['slug']!),
                ),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
}

/// A shared app bar title, so every screen's header is set the same way.
AppBar screenBar(String title, {List<Widget>? actions, bool centre = false}) {
  return AppBar(
    title: Text(title, style: AppText.h3.copyWith(fontSize: 17)),
    centerTitle: centre,
    actions: actions,
  );
}
