/// Every path the app talks to.
///
/// The base URL is compiled in, overridable at build time:
///
/// ```
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
/// ```
///
/// `10.0.2.2` is how an Android emulator reaches the host machine. A physical
/// device on the same network needs the machine's LAN address instead.
class Api {
  Api._();

  static const base = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://takecareconnect.com/api/v1',
  );

  /// The website behind the API, derived rather than declared as a second
  /// constant — pointing the app at a staging server should move the share
  /// links with it, not leave them pointing at production.
  static String get site {
    final trimmed = base.replaceFirst(RegExp(r'/api/v\d+/?$'), '');

    return trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
  }

  /// A shareable public URL for a site-relative path.
  ///
  /// Used for share sheets and for the iOS donate hand-off, both of which need
  /// a link the recipient can open in a browser.
  static String webUrl(String path) => '$site${path.startsWith('/') ? path : '/$path'}';

  static const health = '/health';
  static const home = '/home';
  static const settings = '/settings';
  static const formOptions = '/form-options';

  static const posts = '/posts';
  static String post(String slug) => '/posts/$slug';
  static const postCategories = '/post-categories';
  static String author(String slug) => '/authors/$slug';

  static const businesses = '/businesses';
  static String business(String slug) => '/businesses/$slug';
  static String businessEnquiries(String slug) => '/businesses/$slug/enquiries';
  static const categories = '/categories';
  static const cities = '/cities';

  static const campaigns = '/campaigns';
  static String campaign(String slug) => '/campaigns/$slug';

  static const galleries = '/galleries';
  static String gallery(String slug) => '/galleries/$slug';

  static const press = '/press';
  static const about = '/about';
  static const transparency = '/transparency';
  static String page(String slug) => '/pages/$slug';

  static const donationOptions = '/donations/options';
  static const donationOrder = '/donations/order';
  static String donationStatus(String reference) => '/donations/$reference/status';

  static const contact = '/contact';
  static const volunteerApplications = '/volunteer-applications';
  static const internApplications = '/intern-applications';
  static const interviewRegistrations = '/interview-registrations';
}
