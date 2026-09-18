import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takecare_connect/core/api/api_client.dart';
import 'package:takecare_connect/core/api/cursor_page.dart';
import 'package:takecare_connect/core/api/repository.dart';
import 'package:takecare_connect/core/models/post.dart';
import 'package:takecare_connect/core/router/app_router.dart';
import 'package:takecare_connect/core/theme/app_theme.dart';

/// A filter carried in from somewhere else has to land every time, not once.
///
/// Tapping a subject on the home page opened the full list of stories. It
/// worked the first time and never again, and the reason is the thing that
/// makes the tabs pleasant to use: a tab in a `StatefulShellRoute` is built
/// once and kept alive, so the second arrival rebuilds the widget with a new
/// query while the State — and the field holding the filter — is the same
/// object it was before.
///
/// `initState` cannot see that. `didUpdateWidget` can, and these are the tests
/// that say so.
void main() {
  final categories = [
    const TaxonomyOption(slug: 'her-stories', name: 'Her Stories', count: 3),
    const TaxonomyOption(slug: 'startup-stories', name: 'Startup stories', count: 2),
  ];

  PostSummary post(String slug, String title) => PostSummary.fromJson({
        'slug': slug,
        'title': title,
        'excerpt': 'A sentence about it.',
        'reading_minutes': 3,
      });

  final all = [post('a', 'Everything story'), post('b', 'Another story')];
  final hers = [post('c', 'A weaver in Bhuj')];

  Future<GoRouterHarness> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = buildRouter(initialLocation: '/stories');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(_Fake(all: all, hers: hers, cats: categories)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    return GoRouterHarness(router);
  }

  testWidgets('arriving with a subject shows that subject', (tester) async {
    final harness = await pump(tester);

    harness.go('/stories?category=her-stories');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('A weaver in Bhuj'), findsWidgets);
    expect(find.text('Everything story'), findsNothing);
  });

  /// The one that was broken: a second arrival, on a tab that is already alive.
  testWidgets('arriving a second time with a different subject still filters', (tester) async {
    final harness = await pump(tester);

    harness.go('/stories?category=her-stories');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('A weaver in Bhuj'), findsWidgets);

    // Back out and in again, the way tapping a home tile does.
    harness.go('/');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    harness.go('/stories?category=startup-stories');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Before the fix the screen kept "her-stories" — or, arriving from an
    // unfiltered tab, showed everything.
    expect(find.text('A weaver in Bhuj'), findsNothing);
  });

  testWidgets('arriving with no subject shows everything again', (tester) async {
    final harness = await pump(tester);

    harness.go('/stories?category=her-stories');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    harness.go('/stories');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Everything story'), findsWidgets);
  });
}

/// A tiny wrapper so a test reads as navigation rather than as router plumbing.
class GoRouterHarness {
  GoRouterHarness(this._router);

  final GoRouter _router;

  void go(String location) => _router.go(location);
}

/// Only what the stories screen reads.
class _Fake extends Repository {
  _Fake({required this.all, required this.hers, required this.cats}) : super(ApiClient());

  final List<PostSummary> all;
  final List<PostSummary> hers;
  final List<TaxonomyOption> cats;

  @override
  Future<CursorPage<PostSummary>> posts({
    String? category,
    String? author,
    String? query,
    String? cursor,
  }) async {
    if (category == 'her-stories') return CursorPage<PostSummary>(items: hers);
    if (category == null) return CursorPage<PostSummary>(items: all);

    // Any other subject has nothing in it, which is enough to tell the screens
    // apart without inventing more fixtures.
    return const CursorPage<PostSummary>(items: []);
  }

  @override
  Future<List<TaxonomyOption>> postCategories() async => cats;
}
