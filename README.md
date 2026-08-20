# Takecare Connect

The mobile app for **Take Care International Foundation** — a registered Indian NGO (Section 8,
12A, 80G) that interviews self-employed craftsmen and small businesses across India, publishes
their stories, and raises money for them.

It reads from the foundation's own API at `https://takecareconnect.com/api/v1`, which is served by
the Laravel site in the sibling repository.

## What it is, and what it deliberately is not

This is an **end-user app**: readers, donors, and people who want to volunteer, intern, or put a
business forward to be interviewed.

**There is no login.** Staff and editors use the Filament admin on the web; nothing in this app is
personalised, so an account would be a barrier with nothing behind it. `/api/v1/me` exists on the
server behind `auth:sanctum` as scaffolding, and this app never calls it.

## Running it

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=https://takecareconnect.com/api/v1
```

The base URL is compiled in and defaults to production, so a bare `flutter run` works. Point it
somewhere else for local work:

```bash
# Android emulator reaching a Laravel server on the host machine
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

A physical device on the same network needs the machine's LAN address instead of `10.0.2.2`.

Everything else — the website URL used for share links and the donation hand-off — is derived
from that one value, so pointing the app at staging moves the links with it.

## Layout

```
lib/
  main.dart                 the ProviderScope, the theme, the text-scale clamp
  core/
    api/                    ApiClient (dio), Repository, CursorPage/PagedNotifier, ApiException
    models/                 hand-written, no codegen, defensive defaults on every field
    router/                 buildRouter(), the five-tab StatefulShellRoute, AppShell
    state/                  every Riverpod provider the screens read
    theme/                  AppColors, AppText, AppTheme, AppRadii
    utils/                  Fmt (money and dates), Validate
    widgets/                AppImage, HtmlBody, cards, PagedListView, form fields, state views
  features/
    home/ stories/ craftsmen/ give/ media/ about/ forms/ more/ search/
tool/
  generate_icons.dart       cuts the launcher icons from assets/brand/tcif_logo.png
  live_api_check.dart       parses every live endpoint through the real models
  screenshots.dart          renders every screen to build/screenshots/
```

## Things worth knowing before changing anything

**The palette reserves red.** `AppColors.accent` (`#E63946`) belongs to donate calls to action,
campaign progress bars, and eyebrow labels. Everything structural — app bars, buttons, links,
active states — is `primary` navy. This is the website's own rule; spending the red elsewhere
makes the donate button ordinary.

**The logo is a bundled asset, and the icons are cut from it.** `assets/brand/tcif_logo.png` is
the foundation's roundel, taken from the 512px original rather than the lossy WebP in Settings.
`tool/generate_icons.dart` renders the launcher icons from that same file, so the icon on the home
screen and the mark inside the app cannot drift. It is a raster badge, so `TcifLogo` offers no
`color` — a tint on a multi-colour mark would either do nothing or ruin it — and `onDark` sets it
on a white disc instead, because navy on the footer's dark band all but vanishes. After changing
the mark:

```bash
flutter test tool/generate_icons.dart
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

**Lists are cursor-paginated, not paged.** The API uses Laravel's `cursorPaginate`: no totals, no
page numbers, and the absence of a cursor is the only end signal. Lists therefore use
`PagedNotifier`, which appends — pull-to-refresh calls `refresh()` rather than `ref.invalidate`,
because invalidating would throw away every page the reader had scrolled through.

**The API client has no cookie jar, on purpose.** Sanctum's `EnsureFrontendRequestsAreStateful`
sits in front of the API group and decides statefulness from `Referer`/`Origin`. A native client
sends neither, which is what keeps every POST working. Adding a cookie jar — or building for
**web** — makes requests stateful and every POST returns 419 without a CSRF token.

**Fixed-height horizontal rails need `Expanded`.** A carousel has to give its children a height,
and a card that simply stacks an image over text will overflow the moment a title runs a line
longer than expected, or a reader turns their font size up. The tile cards wrap their text in
`Expanded`/`Flexible` so they adapt instead of striping.

**Donations hand off to the browser.** The form is native up to the moment money changes hands,
then `POST /donations/order` returns an opaque `reference` and the app opens
`https://<site>/donate/checkout/{reference}`. Apple's guideline 3.2.1(vi) allows charitable
donations in an app only through Apple Pay, SMS, or a website opened outside it; Google Play
exempts them from Play Billing but one flow on both stores is worth more than two that diverge.
Confirmation never comes back through the browser — it arrives at the server as a webhook — so
`DonateResultScreen` polls the reference on a widening schedule and, after about two minutes,
says plainly that the payment is still being confirmed rather than spinning forever. A donor who
is unsure whether their money went through donates twice.

The 80G receipt arrives in that same polling. `receipt_url` is a signed, hour-long link keyed on
the reference, and it is **null until the PDF exists** — the file is written by a queued job after
the webhook, so a donor who reaches the screen seconds after paying has a receipt number and no
document. The download button appears when the link does; polling continues past "paid" for
exactly that reason. It opens in the browser rather than downloading into the app, because the
PDF carries the donor's name and PAN.

**Website paths are not app routes.** The API hands out site-relative paths in banner CTAs,
programme cards, and anything an editor types — `/blog/category/tales-of-brands`,
`/interview-today`. Never pass one to `context.go`. `core/router/web_paths.dart` translates them,
and `openWebPath()` sends anything the app cannot show (an external site, the RSS feed, a signed
receipt PDF) to the browser instead. `test/web_paths_test.dart` pins the mapping against the live
menu, because getting this wrong fails silently: the reader just lands on "that page has moved".

**No WebView, and no embedded map.** The Contact screen briefly rendered the website's Google
Maps embed in a `webview_flutter` view. Two things were wrong with that: the Embed API refuses to
render outside an iframe, so a top-level load returns "The Google Maps Embed API must be used in
an iframe" where the map should be; and a live map inside a scrolling form swallows the drag, so
the page appears stuck. Tapping the address hands off to the maps app the person already uses,
which has directions, offline tiles and their saved places. The dependency went with it — there
is no WebView anywhere in this app, and nothing should add one without a better reason.

**A new asset folder needs `flutter clean`.** Editing a file inside a folder pubspec already
declares is picked up; adding a whole new folder is not. The incremental build silently reuses the
previous bundle, ships an APK whose `AssetManifest.json` never mentions it, and the widget simply
renders nothing.

## Checking it

```bash
flutter analyze                       # must be clean
flutter test                          # unit tests: parsing, pagination, money, validators
flutter test tool/live_api_check.dart # parses every live endpoint through the real models
flutter test tool/screenshots.dart    # writes build/screenshots/*.png to look at
flutter build apk --debug
```

`live_api_check.dart` and `screenshots.dart` live in `tool/` rather than `test/` because they need
the network and talk to production — a failure there means the server changed, not that the app
broke. They are worth running after any API change: they are the only things that catch a renamed
key, which the models' defensive defaults would otherwise turn into a silently blank section
rather than an error. Both have already caught real ones — a `social` field that serialises as
`[]` when empty, `focusAreas` in camelCase among snake_case siblings, and a menu row pointing at
a page slug that does not exist.

The screenshot harness fetches its data in `setUpAll` and then serves it from memory, because
`testWidgets` runs inside a fake-async zone where dio's sockets never complete. Both tools clear
`HttpOverrides.global`, which the test binding otherwise sets to something that answers every
request with a 400.
