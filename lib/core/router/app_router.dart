import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/about/about_screen.dart';
import '../../features/about/page_screen.dart';
import '../../features/about/transparency_screen.dart';
import '../../features/craftsmen/craftsman_screen.dart';
import '../../features/craftsmen/craftsmen_screen.dart';
import '../../features/forms/contact_screen.dart';
import '../../features/forms/opportunity_screen.dart';
import '../../features/forms/register_interview_screen.dart';
import '../../features/give/campaign_screen.dart';
import '../../features/give/campaigns_screen.dart';
import '../../features/give/donate_result_screen.dart';
import '../../features/give/donate_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/media/galleries_screen.dart';
import '../../features/media/gallery_screen.dart';
import '../../features/media/press_screen.dart';
import '../../features/more/more_screen.dart';
import '../../features/search/search_screen.dart';
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

          // ------------------------------------------------------- Craftsmen
          StatefulShellBranch(routes: [
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
                GoRoute(
                  path: 'transparency',
                  builder: (context, state) => const TransparencyScreen(),
                ),
                GoRoute(path: 'contact', builder: (context, state) => const ContactScreen()),
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
