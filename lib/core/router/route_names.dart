/// Every route in the app, named once.
///
/// Paths deliberately mirror the website's, so a deep link that works in a
/// browser works here and the two never drift apart in the reader's head.
///
/// Note the `/more`-prefixed group: those screens live inside the More tab's
/// branch, so their real paths carry the prefix. An earlier version of this
/// file declared them without it — fifteen constants that looked usable, were
/// never used, and would have landed a caller on "that page has moved".
class Routes {
  Routes._();

  // The five tabs.
  static const home = '/';
  static const stories = '/stories';
  static const shop = '/shop';
  static const give = '/give';
  static const more = '/more';

  // Stories.
  static const storyDetail = '/stories/:slug';
  static String story(String slug) => '/stories/$slug';
  static const authorDetail = '/authors/:slug';
  static String author(String slug) => '/authors/$slug';

  /*
   | The shop, and the makers, and the interviews with them.
   |
   | All three live in the Shop tab's branch. Craftsmen keep their own
   | `/craftsmen` path rather than moving under `/shop`: every share link the
   | app has ever produced, every deep link, and every `appPathFor('/businesses
   | /...')` result points at it. Only which tab owns them has changed, which is
   | what "craftsmen moved inside the Shop tab" should mean — and it means the
   | Brands segment, a maker's page and a product share one back stack.
   |
   | The Brands segment is `/shop?segment=brands`, never `/shop/brands`, so a
   | product slug can never shadow it. The website needs a reserved-slug list
   | for exactly this collision; there is no reason for the app to inherit it.
   | `?segment=makers` is still read, because older links say that.
   */
  static const productDetail = '/shop/:slug';
  static String product(String slug) => '/shop/$slug';
  static const brandsSegment = '/shop?segment=brands';
  static String shopCategory(String slug) => '/shop?category=$slug';

  static const craftsmen = '/craftsmen';
  static const craftsmanDetail = '/craftsmen/:slug';
  static String craftsman(String slug) => '/craftsmen/$slug';

  static const brands = '/brands';
  static const brandDetail = '/brands/:slug';
  static String brand(String slug) => '/brands/$slug';

  // Campaigns and donating.
  static const campaignDetail = '/give/:slug';
  static String campaign(String slug) => '/give/$slug';
  static const donate = '/donate';
  static const donateResult = '/donate/result/:reference';
  static String donateOutcome(String reference) => '/donate/result/$reference';

  // Everything under the More tab.
  static const galleries = '$more/galleries';
  static String gallery(String slug) => '$more/galleries/$slug';
  static const press = '$more/press';
  static const about = '$more/about';
  static const contact = '$more/contact';
  static const membership = '$more/membership';
  static const sellWithUs = '$more/sell-with-us';
  static const volunteer = '$more/volunteer';
  static const intern = '$more/intern';
  static const registerInterview = '$more/register-interview';

  /// Static pages, by slug: privacy, terms, refunds.
  static String pageFor(String slug) => '$more/pages/$slug';

  /// Retired, along with the website's own page — see
  /// features/about/transparency_screen.dart. The route still exists and sends
  /// the reader home.
  static const transparency = '$more/transparency';

  static const search = '${home}search';
}
