import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/business.dart';
import '../models/campaign.dart';
import '../models/donation.dart';
import '../models/home.dart';
import '../models/media.dart';
import '../models/post.dart';
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
  }) async {
    final json = await _api.post(Api.businessEnquiries(slug), body: {
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
