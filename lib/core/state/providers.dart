import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/cursor_page.dart';
import '../api/repository.dart';
import '../models/business.dart';
import '../models/campaign.dart';
import '../models/donation.dart' show DonationOptions;
import '../models/home.dart';
import '../models/media.dart';
import '../models/post.dart';
import '../models/site.dart';

/// Every provider the screens read.
///
/// Two shapes only:
///
/// **`FutureProvider`** for anything fetched once and shown — a detail page, a
/// settings blob, an option list. `ref.invalidate` refetches it and the screen
/// gets a loading state for free.
///
/// **`NotifierProvider` over [PagedNotifier]** for anything list-shaped, because
/// a `FutureProvider` cannot append. Invalidating one of those would throw away
/// every page the reader had scrolled through; those call `refresh()` instead.
///
/// Family arguments are **records**, which have structural equality in Dart —
/// so `(category: 'weaving', city: null, q: null)` is the same provider
/// instance however many widgets ask for it, and the results are shared rather
/// than refetched per listener.

// --------------------------------------------------------------------- Once

final homeProvider = FutureProvider.autoDispose<HomePayload>(
  (ref) => ref.read(repositoryProvider).home(),
);

/// Not auto-disposed: the footer, the contact screen and the More tab all read
/// this, and it changes about once a year.
final settingsProvider = FutureProvider<SiteSettings>(
  (ref) => ref.read(repositoryProvider).settings(),
);

/// Also kept: every form needs it, and a stale copy is what causes the 422s
/// this endpoint exists to prevent.
final formOptionsProvider = FutureProvider<FormOptions>(
  (ref) => ref.read(repositoryProvider).formOptions(),
);

final postCategoriesProvider = FutureProvider<List<TaxonomyOption>>(
  (ref) => ref.read(repositoryProvider).postCategories(),
);

final businessCategoriesProvider = FutureProvider<List<TaxonomyOption>>(
  (ref) => ref.read(repositoryProvider).categories(),
);

final citiesProvider = FutureProvider<List<TaxonomyOption>>(
  (ref) => ref.read(repositoryProvider).cities(),
);

final postProvider = FutureProvider.autoDispose.family<PostDetail, String>(
  (ref, slug) => ref.read(repositoryProvider).post(slug),
);

/// The editor-curated stories beside an article, excluding the one being read.
///
/// A family on the excluded slug rather than a single provider, because the
/// server does the excluding — so the list genuinely differs per article, and
/// caching one copy would show the reader the story they are already on.
final trendingProvider = FutureProvider.autoDispose.family<List<PostSummary>, String?>(
  (ref, exclude) => ref.read(repositoryProvider).trendingStories(exclude: exclude),
);

final authorProvider = FutureProvider.autoDispose.family<AuthorProfile, String>(
  (ref, slug) => ref.read(repositoryProvider).author(slug),
);

final businessProvider = FutureProvider.autoDispose.family<BusinessDetail, String>(
  (ref, slug) => ref.read(repositoryProvider).business(slug),
);

final campaignProvider = FutureProvider.autoDispose.family<Campaign, String>(
  (ref, slug) => ref.read(repositoryProvider).campaign(slug),
);

final galleryProvider = FutureProvider.autoDispose.family<GalleryDetail, String>(
  (ref, slug) => ref.read(repositoryProvider).gallery(slug),
);

final pressProvider = FutureProvider.autoDispose<List<PressSection>>(
  (ref) => ref.read(repositoryProvider).press(),
);

final aboutProvider = FutureProvider.autoDispose<AboutContent>(
  (ref) => ref.read(repositoryProvider).about(),
);

final transparencyProvider = FutureProvider.autoDispose<TransparencyData>(
  (ref) => ref.read(repositoryProvider).transparency(),
);

final pageProvider = FutureProvider.autoDispose.family<PageContent, String>(
  (ref, slug) => ref.read(repositoryProvider).page(slug),
);

final donationOptionsProvider = FutureProvider.autoDispose<DonationOptions>(
  (ref) => ref.read(repositoryProvider).donationOptions(),
);

// Donation status has no provider on purpose. It is polled on a widening
// schedule that gives up after about two minutes, and that timing is the
// screen's own business — a FutureProvider would have to be invalidated from
// a timer anyway, which is the same code with an extra layer. See
// DonateResultScreen.

// -------------------------------------------------------------------- Lists

typedef PostsQuery = ({String? category, String? author, String? q});

class PostsNotifier extends PagedNotifier<PostSummary, PostsQuery> {
  @override
  Future<CursorPage<PostSummary>> fetch(PostsQuery query, String? cursor) {
    return ref.read(repositoryProvider).posts(
          category: query.category,
          author: query.author,
          query: query.q,
          cursor: cursor,
        );
  }

  @override
  String keyOf(PostSummary item) => item.slug;
}

final postsProvider =
    NotifierProvider.autoDispose.family<PostsNotifier, PagedState<PostSummary>, PostsQuery>(
  PostsNotifier.new,
);

typedef BusinessesQuery = ({String? category, String? city, String? q});

class BusinessesNotifier extends PagedNotifier<BusinessSummary, BusinessesQuery> {
  @override
  Future<CursorPage<BusinessSummary>> fetch(BusinessesQuery query, String? cursor) {
    return ref.read(repositoryProvider).businesses(
          category: query.category,
          city: query.city,
          query: query.q,
          cursor: cursor,
        );
  }

  @override
  String keyOf(BusinessSummary item) => item.slug;
}

final businessesProvider = NotifierProvider.autoDispose
    .family<BusinessesNotifier, PagedState<BusinessSummary>, BusinessesQuery>(
  BusinessesNotifier.new,
);

class CampaignsNotifier extends PagedNotifier<Campaign, String> {
  @override
  Future<CursorPage<Campaign>> fetch(String _, String? cursor) =>
      ref.read(repositoryProvider).campaigns(cursor: cursor);

  @override
  String keyOf(Campaign item) => item.slug;
}

/// The family argument is unused — campaigns take no filters — but the base
/// class is a family notifier, so it gets a constant key.
final campaignsProvider =
    NotifierProvider.autoDispose.family<CampaignsNotifier, PagedState<Campaign>, String>(
  CampaignsNotifier.new,
);

class GalleriesNotifier extends PagedNotifier<GallerySummary, String> {
  @override
  Future<CursorPage<GallerySummary>> fetch(String _, String? cursor) =>
      ref.read(repositoryProvider).galleries(cursor: cursor);

  @override
  String keyOf(GallerySummary item) => item.slug;
}

final galleriesProvider =
    NotifierProvider.autoDispose.family<GalleriesNotifier, PagedState<GallerySummary>, String>(
  GalleriesNotifier.new,
);

/// The key those two unfiltered lists are registered under.
const kAll = 'all';
