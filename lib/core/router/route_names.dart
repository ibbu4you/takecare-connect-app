/// Every route in the app, named once.
///
/// Paths deliberately mirror the website's, so a deep link that works in a
/// browser works here and the two never drift apart in the reader's head.
class Routes {
  Routes._();

  // The five tabs.
  static const home = '/';
  static const stories = '/stories';
  static const craftsmen = '/craftsmen';
  static const give = '/give';
  static const more = '/more';

  // Stories.
  static const storyDetail = '/stories/:slug';
  static String story(String slug) => '/stories/$slug';
  static const authorDetail = '/authors/:slug';
  static String author(String slug) => '/authors/$slug';

  // Craftsmen.
  static const craftsmanDetail = '/craftsmen/:slug';
  static String craftsman(String slug) => '/craftsmen/$slug';

  // Campaigns and donating.
  static const campaignDetail = '/give/:slug';
  static String campaign(String slug) => '/give/$slug';
  static const donate = '/donate';
  static const donateResult = '/donate/result/:reference';
  static String donateOutcome(String reference) => '/donate/result/$reference';

  // Media.
  static const galleries = '/galleries';
  static const galleryDetail = '/galleries/:slug';
  static String gallery(String slug) => '/galleries/$slug';
  static const press = '/press';

  // The foundation.
  static const about = '/about';
  static const transparency = '/transparency';
  static const contact = '/contact';

  // Take part.
  static const volunteer = '/volunteer';
  static const intern = '/intern';
  static const registerInterview = '/register-interview';

  // Static pages, by slug: privacy, terms, refunds.
  static const page = '/pages/:slug';
  static String pageFor(String slug) => '/pages/$slug';

  static const search = '/search';
}
