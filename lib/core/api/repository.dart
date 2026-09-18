import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/business.dart';
import '../models/campaign.dart';
import '../models/donation.dart';
import '../models/home.dart';
import '../models/media.dart';
import '../models/post.dart';
import '../models/shop.dart';
import '../models/site.dart';
import 'api_client.dart';
import 'api_endpoints.dart';
import 'cursor_page.dart';

final repositoryProvider = Provider<Repository>(
  (ref) => Repository(ref.read(apiClientProvider)),
);

/// Everything the app asks the server for.
///
/// One class rather than one per feature: the endpoints are uniform — fetch,
/// unwrap `data`, parse — and eight files of three methods each would be
/// filing, not structure. The screens see typed models and never a Map.
class Repository {
  Repository(this._api);

  final ApiClient _api;

  // ------------------------------------------------------------------ Home

  Future<HomePayload> home() async {
    final json = await _api.get(Api.home);

    return HomePayload.fromJson(_object(json));
  }

  Future<SiteSettings> settings() async {
    final json = await _api.get(Api.settings);

    return SiteSettings.fromJson(_object(json));
  }

  Future<FormOptions> formOptions() async {
    final json = await _api.get(Api.formOptions);

    return FormOptions.fromJson(_object(json));
  }

  // ---------------------------------------------------------------- Stories

  Future<CursorPage<PostSummary>> posts({
    String? category,
    String? author,
    String? query,
    String? cursor,
  }) async {
    final json = await _api.get(Api.posts, query: {
      if (category != null) 'category': category,
      if (author != null) 'author': author,
      if (query != null && query.isNotEmpty) 'q': query,
      if (cursor != null) 'cursor': cursor,
    });

    return CursorPage.fromJson(json, PostSummary.fromJson);
  }

  Future<PostDetail> post(String slug) async {
    final json = await _api.get(Api.post(slug));

    return PostDetail.fromJson(_object(json));
  }

  Future<List<TaxonomyOption>> postCategories() async {
    final json = await _api.get(Api.postCategories);

    return _list(json, TaxonomyOption.fromJson);
  }

  /// The editor-curated list the website prints beside every article.
  ///
  /// [exclude] is the story the reader is already on. The server applies it to
  /// its recency fallback only — a story an editor ticked is shown wherever
  /// they ticked it.
  Future<List<PostSummary>> trendingStories({String? exclude}) async {
    final json = await _api.get(Api.trendingStories, query: {
      if (exclude != null) 'exclude': exclude,
    });

    return _list(json, PostSummary.fromJson);
  }

  Future<AuthorProfile> author(String slug) async {
    final json = await _api.get(Api.author(slug));

    return AuthorProfile.fromJson(_object(json));
  }

  // -------------------------------------------------------------- Craftsmen

  Future<CursorPage<BusinessSummary>> businesses({
    String? category,
    String? city,
    String? query,
    String? cursor,
  }) async {
    final json = await _api.get(Api.businesses, query: {
      if (category != null) 'category': category,
      if (city != null) 'city': city,
      if (query != null && query.isNotEmpty) 'q': query,
      if (cursor != null) 'cursor': cursor,
    });

    return CursorPage.fromJson(json, BusinessSummary.fromJson);
  }

  Future<BusinessDetail> business(String slug) async {
    final json = await _api.get(Api.business(slug));

    return BusinessDetail.fromJson(_object(json));
  }

  Future<List<TaxonomyOption>> categories() async =>
      _list(await _api.get(Api.categories), TaxonomyOption.fromJson);

  Future<List<TaxonomyOption>> cities() async =>
      _list(await _api.get(Api.cities), TaxonomyOption.fromJson);

  /// Returns the craftsman's number for a reveal, null for a written enquiry.
  Future<({String? phone, String message})> sendEnquiry({
    required String slug,
    required String name,
    required String phone,
    required String intent,
    String? email,
    String? message,
  }) =>
      _enquiry(
        Api.businessEnquiries(slug),
        name: name,
        phone: phone,
        intent: intent,
        email: email,
        message: message,
      );

  /// The same question, asked about one particular product.
  ///
  /// Shares [_enquiry] with the interview above rather than repeating it: the
  /// two answer in the same envelope and the reveal-versus-send rule is the
  /// same, so a second copy would only be somewhere for them to diverge.
  Future<({String? phone, String message})> sendProductEnquiry({
    required String slug,
    required String name,
    required String phone,
    required String intent,
    String? email,
    String? message,
  }) =>
      _enquiry(
        Api.productEnquiries(slug),
        name: name,
        phone: phone,
        intent: intent,
        email: email,
        message: message,
      );

  Future<({String? phone, String message})> _enquiry(
    String path, {
    required String name,
    required String phone,
    required String intent,
    String? email,
    String? message,
  }) async {
    final json = await _api.post(path, body: {
      'name': name,
      'phone': phone,
      'intent': intent,
      if (email != null) 'email': email,
      if (message != null) 'message': message,
      ..._honeypot,
    });

    final data = _object(json);

    return (
      phone: data['phone'] as String?,
      message: (data['message'] ?? '') as String,
    );
  }

  // ------------------------------------------------------------------- Shop

  /// Products, filtered the way the website filters them.
  ///
  /// The plural parameters are sent as repeated keys (`categories[]=a&
  /// categories[]=b`), which is what the server's validator expects — see the
  /// `listFormat` note in ApiClient. Two ticked crafts widen the results rather
  /// than narrowing them to nothing, because a product has one category.
  Future<CursorPage<ShopProduct>> products({
    List<String> categories = const [],
    List<String> makers = const [],
    String? city,
    String? query,
    double? priceMin,
    double? priceMax,
    String? cursor,
  }) async {
    final json = await _api.get(Api.products, query: {
      if (categories.isNotEmpty) 'categories[]': categories,
      if (makers.isNotEmpty) 'makers[]': makers,
      if (city != null) 'city': city,
      if (query != null && query.isNotEmpty) 'q': query,
      if (priceMin != null) 'price_min': priceMin,
      if (priceMax != null) 'price_max': priceMax,
      if (cursor != null) 'cursor': cursor,
    });

    return CursorPage.fromJson(json, ShopProduct.fromJson);
  }

  Future<ShopProductDetail> product(String slug) async {
    final json = await _api.get(Api.product(slug));

    return ShopProductDetail.fromJson(_object(json));
  }

  Future<ShopFilters> shopFilters() async {
    final json = await _api.get(Api.shopFilters);

    return ShopFilters.fromJson(_object(json));
  }

  Future<List<TaxonomyOption>> productCategories() async =>
      _list(await _api.get(Api.productCategories), TaxonomyOption.fromJson);

  /// A plain list, not a page.
  ///
  /// The server orders these by how much each maker has on the shelf, which a
  /// cursor cannot encode — see its BrandController. The set is bounded by
  /// paying members with something listed.
  Future<List<Brand>> brands({String? craft, String? city, String? query}) async {
    final json = await _api.get(Api.brands, query: {
      if (craft != null) 'craft': craft,
      if (city != null) 'city': city,
      if (query != null && query.isNotEmpty) 'q': query,
    });

    return _list(json, Brand.fromJson);
  }

  Future<Brand> brand(String slug) async {
    final json = await _api.get(Api.brand(slug));

    return Brand.fromJson(_object(json));
  }

  Future<MembershipContent> membership() async {
    final json = await _api.get(Api.membership);

    return MembershipContent.fromJson(_object(json));
  }

  // -------------------------------------------------------------- Campaigns

  Future<CursorPage<Campaign>> campaigns({String? cursor}) async {
    final json = await _api.get(Api.campaigns, query: {
      if (cursor != null) 'cursor': cursor,
    });

    return CursorPage.fromJson(json, Campaign.fromJson);
  }

  Future<Campaign> campaign(String slug) async {
    final json = await _api.get(Api.campaign(slug));

    return Campaign.fromJson(_object(json));
  }

  // ------------------------------------------------------------------ Media

  Future<CursorPage<GallerySummary>> galleries({String? cursor}) async {
    final json = await _api.get(Api.galleries, query: {
      if (cursor != null) 'cursor': cursor,
    });

    return CursorPage.fromJson(json, GallerySummary.fromJson);
  }

  Future<GalleryDetail> gallery(String slug) async {
    final json = await _api.get(Api.gallery(slug));

    return GalleryDetail.fromJson(_object(json));
  }

  Future<List<PressSection>> press() async =>
      _list(await _api.get(Api.press), PressSection.fromJson);

  // ------------------------------------------------------------------ Pages

  Future<AboutContent> about() async {
    final json = await _api.get(Api.about);

    return AboutContent.fromJson(_object(json));
  }

  Future<TransparencyData> transparency() async {
    final json = await _api.get(Api.transparency);

    return TransparencyData.fromJson(_object(json));
  }

  Future<PageContent> page(String slug) async {
    final json = await _api.get(Api.page(slug));

    return PageContent.fromJson(_object(json));
  }

  // -------------------------------------------------------------- Donations

  Future<DonationOptions> donationOptions() async {
    final json = await _api.get(Api.donationOptions);

    return DonationOptions.fromJson(_object(json));
  }

  Future<CheckoutHandoff> createDonation(Map<String, dynamic> body) async {
    final json = await _api.post(Api.donationOrder, body: body);

    return CheckoutHandoff.fromJson(_object(json));
  }

  Future<DonationStatus> donationStatus(String reference) async {
    final json = await _api.get(Api.donationStatus(reference));

    return DonationStatus.fromJson(_object(json));
  }

  // ------------------------------------------------------------------ Forms

  /// Each returns the server's own confirmation wording, so the app's snackbar
  /// says exactly what the website says.
  Future<String> sendContact(Map<String, dynamic> body) =>
      _message(Api.contact, {...body, ..._honeypot});

  Future<String> applyVolunteer(Map<String, dynamic> body) =>
      _message(Api.volunteerApplications, {...body, ..._decoyUrl});

  Future<String> applyIntern(Map<String, dynamic> body) =>
      _message(Api.internApplications, {...body, ..._decoyUrl});

  Future<String> registerForInterview(Map<String, dynamic> body) =>
      _message(Api.interviewRegistrations, {...body, ..._decoyUrl});

  /// `_decoyUrl`, not `_honeypot` — a craftsman applying to sell is asked for
  /// their real `website`, so the decoy on this form is `website_url`. See the
  /// note below; getting it the wrong way round fails silently.
  Future<String> applyToSell(Map<String, dynamic> body) =>
      _message(Api.vendorApplications, {...body, ..._decoyUrl});

  Future<String> subscribeToNewsletter({required String email, String? name}) =>
      _message(Api.newsletter, {
        'email': email,
        if (name != null && name.isNotEmpty) 'name': name,
        ..._honeypot,
      });

  Future<String> _message(String path, Map<String, dynamic> body) async {
    final json = await _api.post(path, body: body);

    return (_object(json)['message'] ?? 'Thank you — that has reached us.') as String;
  }

  /// The honeypots, added here so no screen can forget one.
  ///
  /// Every submission FormRequest validates a decoy field as
  /// `nullable|prohibited`: a bot that fills in every input on a page gives
  /// itself away, and a real visitor never sees it. The rule passes when the
  /// key is absent *or* empty, so the app sends the empty string — identical
  /// to what the website posts, which keeps the two surfaces
  /// indistinguishable to the validator.
  ///
  /// **The field is not called the same thing on every form.** Contact and
  /// enquiry use `website`; the applications and the interview registration
  /// use `website_url`, because on those `website` is a real question — the
  /// business's own address. Sending the wrong one fails silently rather than
  /// loudly, which is exactly why it is not left to a caller to remember.
  static const _honeypot = {'website': ''};
  static const _decoyUrl = {'website_url': ''};

  // ----------------------------------------------------------------- Shapes

  Map<String, dynamic> _object(Map<String, dynamic> json) {
    final data = json['data'];

    return data is Map<String, dynamic> ? data : json;
  }

  List<T> _list<T>(Map<String, dynamic> json, T Function(Map<String, dynamic>) parse) {
    return ((json['data'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(parse)
        .toList();
  }
}
